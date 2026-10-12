"""Tests for the rule-based transaction categorizer."""

import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.services.categorizer import TransactionCategorizer, CATEGORY_KEYWORDS, DEFAULT_CATEGORY_MAP  # noqa: E402


@pytest.fixture
def categorizer():
    return TransactionCategorizer()


class TestKeywordMatching:
    def test_food_keyword(self, categorizer):
        r = categorizer.categorize("Shoprite groceries", 250)
        assert r["category_id"] == DEFAULT_CATEGORY_MAP["Food"]

    def test_transport_keyword(self, categorizer):
        r = categorizer.categorize("Minibus fare to town", 15)
        assert r["category_id"] == DEFAULT_CATEGORY_MAP["Transport"]

    def test_utilities_keyword(self, categorizer):
        r = categorizer.categorize("ZESCO electricity bill", 300)
        assert r["category_id"] == DEFAULT_CATEGORY_MAP["Utilities"]

    def test_communication_keyword(self, categorizer):
        r = categorizer.categorize("MTN airtime top up", 20)
        assert r["category_id"] == DEFAULT_CATEGORY_MAP["Communication"]

    def test_education_keyword(self, categorizer):
        r = categorizer.categorize("University tuition fees", 5000)
        assert r["category_id"] == DEFAULT_CATEGORY_MAP["Education"]

    def test_healthcare_keyword(self, categorizer):
        r = categorizer.categorize("Pharmacy medicine", 80)
        assert r["category_id"] == DEFAULT_CATEGORY_MAP["Healthcare"]

    def test_case_insensitive(self, categorizer):
        assert (
            categorizer.categorize("SHOPRITE", 100)["category_name"] == "Food"
        )

    def test_no_match_defaults_to_other_low_confidence(self, categorizer):
        r = categorizer.categorize("quantum flux", 75)
        assert r["category_id"] == "cat-other"
        assert r["category_name"] == "Other"
        assert r["confidence"] == pytest.approx(0.1)

    def test_unknown_category_ids_fall_back_to_other(self, categorizer):
        categorizer.category_map = {}  # no category ids mapped
        r = categorizer.categorize("Restaurant dinner", 150)
        assert r["category_id"] == "cat-other"


class TestAmountHeuristics:
    def test_small_transport_amount_boosts_confidence(self, categorizer):
        base = categorizer.categorize("taxi ride", 500.0)["confidence"]
        boosted = categorizer.categorize("taxi ride", 15.0)["confidence"]
        assert boosted > base

    def test_small_communication_amount_boosts_confidence(self, categorizer):
        base = categorizer.categorize("airtime", 500.0)["confidence"]
        boosted = categorizer.categorize("airtime", 30.0)["confidence"]
        assert boosted > base

    def test_large_housing_amount_boosts_confidence(self, categorizer):
        base = categorizer.categorize("house rent", 300.0)["confidence"]
        boosted = categorizer.categorize("house rent", 2500.0)["confidence"]
        assert boosted > base


class TestConfidenceBounds:
    def test_confidence_capped_at_095(self, categorizer):
        r = categorizer.categorize(
            "shoprite market grocery food lunch dinner restaurant meal", 100
        )
        assert r["confidence"] <= 0.95

    def test_confidence_grows_with_keyword_count(self, categorizer):
        one = categorizer.categorize("shoprite", 100)["confidence"]
        two = categorizer.categorize("shoprite grocery", 100)["confidence"]
        assert two > one


class TestBatch:
    def test_batch_categorize_returns_one_result_per_input(self, categorizer):
        txs = [
            {"description": "shoprite", "amount": 100},
            {"description": "minibus", "amount": 10},
            {"description": "zesco", "amount": 200},
        ]
        results = categorizer.batch_categorize(txs)
        assert len(results) == 3
        assert results[0]["category_name"] == "Food"
        assert results[1]["category_name"] == "Transport"
        assert results[2]["category_name"] == "Utilities"


class TestCategoryTable:
    def test_all_keyword_categories_have_category_ids(self):
        missing = set(CATEGORY_KEYWORDS) - set(DEFAULT_CATEGORY_MAP)
        assert not missing, f"categories without ids: {missing}"

    def test_category_tables_are_nonempty(self):
        assert CATEGORY_KEYWORDS
        assert DEFAULT_CATEGORY_MAP
