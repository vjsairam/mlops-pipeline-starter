import logging
from typing import Any, Dict, List, Optional, Tuple
from datetime import datetime, timezone
import json

import pandas as pd
import great_expectations as gx
from great_expectations.core import ExpectationConfiguration
from great_expectations.core.batch import RuntimeBatchRequest
from great_expectations.data_context import DataContext

logger = logging.getLogger(__name__)


class DataValidator:
    """Base class for data validation using Great Expectations."""

    def __init__(self, context_root_dir: str = "./data_quality"):
        """Initialize the DataValidator with Great Expectations context."""
        self.context = gx.get_context(context_root_dir=context_root_dir)
        self.validation_results = []

    def validate_schema(
        self,
        df: pd.DataFrame,
        expected_columns: List[str],
        expected_dtypes: Dict[str, str]
    ) -> Dict[str, Any]:
        """Validate dataframe schema.

        Args:
            df: DataFrame to validate
            expected_columns: List of expected column names
            expected_dtypes: Dictionary mapping column names to expected data types

        Returns:
            Dictionary containing validation results
        """
        if df is None or df.empty:
            return {
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "validation_type": "schema",
                "passed": False,
                "errors": [{"type": "empty_dataframe", "message": "DataFrame is None or empty"}]
            }

        validation_results = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "validation_type": "schema",
            "passed": True,
            "errors": []
        }

        # Check for missing columns
        missing_columns = set(expected_columns) - set(df.columns)
        if missing_columns:
            validation_results["passed"] = False
            validation_results["errors"].append({
                "type": "missing_columns",
                "columns": list(missing_columns)
            })

        # Check for unexpected columns
        unexpected_columns = set(df.columns) - set(expected_columns)
        if unexpected_columns:
            validation_results["errors"].append({
                "type": "unexpected_columns",
                "columns": list(unexpected_columns)
            })

        # Check data types
        dtype_mismatches = []
        for col, expected_dtype in expected_dtypes.items():
            if col in df.columns:
                actual_dtype = str(df[col].dtype)
                if not self._dtype_compatible(actual_dtype, expected_dtype):
                    dtype_mismatches.append({
                        "column": col,
                        "expected": expected_dtype,
                        "actual": actual_dtype
                    })

        if dtype_mismatches:
            validation_results["passed"] = False
            validation_results["errors"].append({
                "type": "dtype_mismatch",
                "mismatches": dtype_mismatches
            })

        return validation_results

    def validate_data_quality(
        self,
        df: pd.DataFrame,
        expectation_suite_name: str,
        datasource_name: str = "runtime_datasource",
        data_asset_name: str = "runtime_data"
    ) -> Tuple[bool, Dict[str, Any]]:
        """Run Great Expectations validation suite on dataframe."""
        try:
            # Create runtime batch request
            batch_request = RuntimeBatchRequest(
                datasource_name=datasource_name,
                data_connector_name="default_runtime_data_connector",
                data_asset_name=data_asset_name,
                runtime_parameters={"batch_data": df},
                batch_identifiers={"default_identifier_name": "default_identifier"}
            )

            # Get expectation suite
            expectation_suite = self.context.get_expectation_suite(
                expectation_suite_name=expectation_suite_name
            )

            # Create validator
            validator = self.context.get_validator(
                batch_request=batch_request,
                expectation_suite_name=expectation_suite_name
            )

            # Run validation
            validation_result = validator.validate()

            # Parse results
            passed = validation_result["success"]

            result_summary = {
                "suite_name": expectation_suite_name,
                "passed": passed,
                "timestamp": datetime.utcnow().isoformat(),
                "statistics": validation_result["statistics"],
                "failed_expectations": []
            }

            if not passed:
                for result in validation_result["results"]:
                    if not result["success"]:
                        result_summary["failed_expectations"].append({
                            "expectation": result["expectation_config"]["expectation_type"],
                            "kwargs": result["expectation_config"]["kwargs"],
                            "result": result["result"]
                        })

            return passed, result_summary

        except Exception as e:
            logger.error(f"Validation failed: {str(e)}")
            return False, {"error": str(e)}

    def validate_statistical_properties(
        self,
        df: pd.DataFrame,
        numeric_columns: List[str],
        thresholds: Dict[str, Dict[str, float]]
    ) -> Dict[str, Any]:
        """Validate statistical properties of numeric columns.

        Args:
            df: DataFrame to validate
            numeric_columns: List of numeric column names to validate
            thresholds: Dictionary of validation thresholds per column

        Returns:
            Dictionary containing validation results
        """
        validation_results = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "validation_type": "statistical",
            "passed": True,
            "violations": []
        }

        for col in numeric_columns:
            if col not in df.columns:
                continue

            stats = {
                "mean": df[col].mean(),
                "std": df[col].std(),
                "min": df[col].min(),
                "max": df[col].max(),
                "null_rate": df[col].isnull().mean()
            }

            if col in thresholds:
                col_thresholds = thresholds[col]
                violations = []

                for stat_name, stat_value in stats.items():
                    if f"{stat_name}_min" in col_thresholds:
                        if stat_value < col_thresholds[f"{stat_name}_min"]:
                            violations.append({
                                "stat": stat_name,
                                "value": stat_value,
                                "threshold": col_thresholds[f"{stat_name}_min"],
                                "type": "below_min"
                            })

                    if f"{stat_name}_max" in col_thresholds:
                        if stat_value > col_thresholds[f"{stat_name}_max"]:
                            violations.append({
                                "stat": stat_name,
                                "value": stat_value,
                                "threshold": col_thresholds[f"{stat_name}_max"],
                                "type": "above_max"
                            })

                if violations:
                    validation_results["passed"] = False
                    validation_results["violations"].append({
                        "column": col,
                        "violations": violations
                    })

        return validation_results

    def validate_freshness(
        self,
        df: pd.DataFrame,
        timestamp_column: str,
        max_staleness_hours: int = 24
    ) -> Dict[str, Any]:
        """Validate data freshness based on timestamp column.

        Args:
            df: DataFrame to validate
            timestamp_column: Name of the timestamp column
            max_staleness_hours: Maximum allowed staleness in hours

        Returns:
            Dictionary containing validation results
        """
        validation_results = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "validation_type": "freshness",
            "passed": True,
            "details": {}
        }

        if timestamp_column not in df.columns:
            validation_results["passed"] = False
            validation_results["details"]["error"] = f"Timestamp column '{timestamp_column}' not found"
            return validation_results

        # Convert to datetime (create a copy to avoid mutating input)
        df_copy = df.copy()
        df_copy[timestamp_column] = pd.to_datetime(df_copy[timestamp_column])

        # Get latest timestamp
        latest_timestamp = df_copy[timestamp_column].max()

        # Handle timezone-aware and timezone-naive timestamps
        if latest_timestamp.tz is not None:
            current_time = pd.Timestamp.now(tz=latest_timestamp.tz)
        else:
            current_time = pd.Timestamp.now()

        # Calculate staleness
        staleness_hours = (current_time - latest_timestamp).total_seconds() / 3600

        validation_results["details"] = {
            "latest_timestamp": latest_timestamp.isoformat(),
            "current_time": current_time.isoformat(),
            "staleness_hours": staleness_hours,
            "max_staleness_hours": max_staleness_hours
        }

        if staleness_hours > max_staleness_hours:
            validation_results["passed"] = False
            validation_results["details"]["error"] = f"Data is {staleness_hours:.2f} hours old, exceeds max of {max_staleness_hours} hours"

        return validation_results

    def create_expectation_suite(
        self,
        suite_name: str,
        expectations: List[ExpectationConfiguration]
    ) -> None:
        """Create or update an expectation suite."""
        suite = self.context.create_expectation_suite(
            expectation_suite_name=suite_name,
            overwrite_existing=True
        )

        for expectation in expectations:
            suite.add_expectation(expectation_configuration=expectation)

        self.context.save_expectation_suite(suite)
        logger.info(f"Created expectation suite: {suite_name}")

    def generate_validation_report(
        self,
        validation_results: List[Dict[str, Any]],
        output_path: str
    ) -> None:
        """Generate validation report in JSON format.

        Args:
            validation_results: List of validation result dictionaries
            output_path: Path where to save the report
        """
        report = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "total_validations": len(validation_results),
            "passed": sum(1 for r in validation_results if r.get("passed", False)),
            "failed": sum(1 for r in validation_results if not r.get("passed", False)),
            "results": validation_results
        }

        with open(output_path, "w", encoding="utf-8") as f:
            json.dump(report, f, indent=2, default=str)

        logger.info(f"Validation report saved to {output_path}")

    def _dtype_compatible(self, actual: str, expected: str) -> bool:
        """Check if actual dtype is compatible with expected dtype."""
        dtype_mappings = {
            "int": ["int8", "int16", "int32", "int64", "Int8", "Int16", "Int32", "Int64"],
            "float": ["float16", "float32", "float64", "Float32", "Float64"],
            "string": ["object", "string", "category"],
            "datetime": ["datetime64", "datetime64[ns]", "datetime64[ns, UTC]"],
            "bool": ["bool", "boolean"]
        }

        for dtype_family, dtypes in dtype_mappings.items():
            if expected == dtype_family:
                return any(dtype in actual for dtype in dtypes)

        return actual == expected