"""API-level tests for the ML service endpoints (no DB required)."""

import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from fastapi.testclient import TestClient  # noqa: E402


@pytest.fixture(scope="module")
def client():
    from app.main import app

    return TestClient(app)


class TestHealth:
    def test_health_returns_ok(self, client):
        r = client.get("/ml/v1/health")
        assert r.status_code == 200
        assert r.json() == {"status": "ok", "service": "ml-service"}


class TestCategorize:
    def test_categorizes_food(self, client):
        r = client.post("/ml/v1/categorize", json={"description": "KFC lunch", "amount": 120})
        assert r.status_code == 200
        body = r.json()
        assert body["category_name"] == "Food"
        assert 0 <= body["confidence"] <= 1

    def test_batch_categorize(self, client):
        r = client.post(
            "/ml/v1/categorize-batch",
            json={
                "transactions": [
                    {"description": "shoprite run", "amount": 400},
                    {"description": "uber", "amount": 90},
                ]
            },
        )
        assert r.status_code == 200
        results = r.json()["results"]
        assert len(results) == 2
        assert results[0]["category_id"] != results[1]["category_id"]

    def test_rejects_missing_amount(self, client):
        r = client.post("/ml/v1/categorize", json={"description": "no amount"})
        assert r.status_code == 422


class TestOverspending:
    def _payload(self, **overrides):
        base = {
            "daily_expenses": [
                {"date": "2026-10-01", "amount": 50},
                {"date": "2026-10-02", "amount": 45},
            ],
            "total_budget": 2000,
            "days_elapsed": 2,
            "days_in_month": 31,
        }
        base.update(overrides)
        return base

    def test_predicts_overspending(self, client):
        r = client.post("/ml/v1/predictions/overspending", json=self._payload())
        assert r.status_code == 200
        body = r.json()
        assert body["prediction_available"] is True
        assert body["model"] == "linear_trend_v1"
        assert "message" in body

    def test_rejects_zero_budget(self, client):
        r = client.post("/ml/v1/predictions/overspending", json=self._payload(total_budget=0))
        assert r.status_code == 422

    def test_rejects_days_in_month_over_31(self, client):
        r = client.post(
            "/ml/v1/predictions/overspending", json=self._payload(days_in_month=32)
        )
        assert r.status_code == 422

    def test_rejects_non_positive_days_elapsed(self, client):
        r = client.post(
            "/ml/v1/predictions/overspending", json=self._payload(days_elapsed=0)
        )
        assert r.status_code == 422

    def test_rejects_empty_expense_list(self, client):
        r = client.post(
            "/ml/v1/predictions/overspending", json=self._payload(daily_expenses=[])
        )
        assert r.status_code == 422
