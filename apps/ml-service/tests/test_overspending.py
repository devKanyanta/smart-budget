"""Tests for the overspending / budget-exhaustion predictor."""

import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.services.overspending import OverspendingPredictor  # noqa: E402


@pytest.fixture
def predictor():
    return OverspendingPredictor()


def daily_series(amounts):
    """Build daily_expenses spanning the first len(amounts) days of Oct 2026."""
    return [
        {"date": f"2026-10-{i + 1:02d}", "amount": amt}
        for i, amt in enumerate(amounts)
    ]


class TestUnavailablePredictions:
    def test_no_expenses_returns_unavailable(self, predictor):
        result = predictor.predict(
            daily_expenses=[], total_budget=1000, days_elapsed=10, days_in_month=31
        )
        assert result["prediction_available"] is False
        assert "message" in result

    def test_zero_budget_returns_unavailable(self, predictor):
        result = predictor.predict(
            daily_expenses=daily_series([50, 50]), total_budget=0,
            days_elapsed=2, days_in_month=31,
        )
        assert result["prediction_available"] is False

    def test_negative_budget_returns_unavailable(self, predictor):
        result = predictor.predict(
            daily_expenses=daily_series([50]), total_budget=-100,
            days_elapsed=1, days_in_month=31,
        )
        assert result["prediction_available"] is False


class TestSteadyPace:
    def test_flat_spend_projected_linearly(self, predictor):
        # K50/day for 10 days of Oct (31 days), budget K2000 -> well on pace
        result = predictor.predict(
            daily_expenses=daily_series([50.0] * 10),
            total_budget=2000.0,
            days_elapsed=10,
            days_in_month=31,
        )
        assert result["prediction_available"] is True
        assert result["total_spent"] == 500.0
        assert result["avg_daily_spend"] == 50.0
        # Flat trend -> projection = 50 * 31 = 1550 (< 2000 budget)
        assert result["predicted_month_end_spend"] == pytest.approx(1550.0, abs=1.0)
        assert result["will_overspend"] is False
        assert result["risk_level"] == "low"
        # Ideal daily = (2000-500)/21 ≈ 71.4
        assert result["recommended_daily_spend"] == pytest.approx(71.43, abs=0.5)

    def test_flat_spend_overspending_pace(self, predictor):
        # K100/day for 10 days -> K3100 projected vs K2000 budget
        result = predictor.predict(
            daily_expenses=daily_series([100.0] * 10),
            total_budget=2000.0,
            days_elapsed=10,
            days_in_month=31,
        )
        assert result["will_overspend"] is True
        assert result["risk_level"] == "high"  # pace ratio 100/(1000/21) is way > 1.25
        assert result["overspend_amount"] > 0
        assert result["estimated_exhaustion_date"] is not None
        assert result["days_to_exhaustion"] is not None

    def test_multi_day_same_date_aggregates(self, predictor):
        # Two entries the same dasy count together
        expenses = [
            {"date": "2026-10-01", "amount": 30},
            {"date": "2026-10-01", "amount": 20},
        ]
        result = predictor.predict(
            daily_expenses=expenses, total_budget=2000,
            days_elapsed=2, days_in_month=31,
        )
        assert result["total_spent"] == pytest.approx(50.0)

    def test_zero_spend_days_filled(self, predictor):
        # Only spent on day 1 and day 5 — days 2-4 must count as 0
        expenses = [
            {"date": "2026-10-01", "amount": 100},
            {"date": "2026-10-05", "amount": 100},
        ]
        result = predictor.predict(
            daily_expenses=expenses, total_budget=2000,
            days_elapsed=5, days_in_month=31,
        )
        assert result["total_spent"] == pytest.approx(200.0)
        assert result["avg_daily_spend"] == pytest.approx(40.0)


class TestTrendDetection:
    def test_rising_trend_flags_risk(self, predictor):
        # Escalating: 10, 20, ..., 100 — clearly rising spend
        result = predictor.predict(
            daily_expenses=daily_series([float(10 * (i + 1)) for i in range(10)]),
            total_budget=1500.0,
            days_elapsed=10,
            days_in_month=31,
        )
        assert result["r_squared"] > 0.5
        assert result["risk_level"] in ("medium", "high")
        assert result["predicted_month_end_spend"] > 1500.0

    def test_r_squared_of_flat_series_is_special(self, predictor):
        # Flat series: ss_tot = 0, so r_squared must degrade to 0 gracefully
        result = predictor.predict(
            daily_expenses=daily_series([40.0] * 6),
            total_budget=2000, days_elapsed=6, days_in_month=31,
        )
        assert result["r_squared"] == 0.0

    def test_trend_adjustment_blends_by_fit(self, predictor):
        # Strong linear rise: adjusted daily should exceed the plain average
        amounts = [10.0 * (i + 1) for i in range(10)]  #pace accelerates
        result = predictor.predict(
            daily_expenses=daily_series(amounts),
            total_budget=1300.0,
            days_elapsed=10,
            days_in_month=31,
        )
        avg = 55.0
        assert result["predicted_month_end_spend"] / 31 > avg * 0.9


class TestRiskAndConfidence:
    def test_low_pace_is_low_risk(self, predictor):
        result = predictor.predict(
            daily_expenses=daily_series([20.0] * 15),
            total_budget=3000.0,
            days_elapsed=15,
            days_in_month=31,
        )
        assert result["risk_level"] == "low"

    def test_short_history_gives_low_confidence(self, predictor):
        result = predictor.predict(
            daily_expenses=daily_series([100.0] * 3),
            total_budget=3000,
            days_elapsed=3, days_in_month=31,
        )
        assert result["confidence"] == "low"

    def test_medium_history_gives_medium_confidence(self, predictor):
        result = predictor.predict(
            daily_expenses=daily_series([100.0] * 10),
            total_budget=5000,
            days_elapsed=10, days_in_month=31,
        )
        assert result["confidence"] == "medium"

    def test_long_history_with_fit_gives_high_confidence(self, predictor):
        result = predictor.predict(
            daily_expenses=daily_series([10.0 * (i + 1) for i in range(15)]),
            total_budget=1000,
            days_elapsed=15, days_in_month=31,
        )
        assert result["confidence"] == "high"

    def test_over_half_budget_spent_is_overspend(self, predictor):
        # Already spent more than the entire budget on day 1
        result = predictor.predict(
            daily_expenses=daily_series([9999.0]),
            total_budget=500.0,
            days_elapsed=1, days_in_month=31,
        )
        assert result["will_overspend"] is True
        assert result["overspend_amount"] > 0
        assert result["risk_level"] == "high"


class TestOutputShape:
    def test_all_expected_keys_present(self, predictor):
        result = predictor.predict(
            daily_expenses=daily_series([50.0] * 5),
            total_budget=2000, days_elapsed=5, days_in_month=31,
        )
        for key in (
            "prediction_available", "predicted_month_end_spend", "total_budget",
            "total_spent", "overspend_amount", "will_overspend",
            "will_exhaust_before_month_end", "estimated_exhaustion_date",
            "days_to_exhaustion", "avg_daily_spend", "recommended_daily_spend",
            "budget_pace_ratio", "risk_level", "confidence", "r_squared",
            "model", "message",
        ):
            assert key in result
        assert result["model"] == "linear_trend_v1"

    def test_message_mentions_kwacha(self, predictor):
        result = predictor.predict(
            daily_expenses=daily_series([50.0] * 5),
            total_budget=2000, days_elapsed=5, days_in_month=31,
        )
        assert "K" in result["message"]

    def test_days_to_exhaustion_none_when_on_track(self, predictor):
        result = predictor.predict(
            daily_expenses=daily_series([10.0] * 5),
            total_budget=5000, days_elapsed=5, days_in_month=31,
        )
        assert result["will_overspend"] is False
        assert result["estimated_exhaustion_date"] is None
