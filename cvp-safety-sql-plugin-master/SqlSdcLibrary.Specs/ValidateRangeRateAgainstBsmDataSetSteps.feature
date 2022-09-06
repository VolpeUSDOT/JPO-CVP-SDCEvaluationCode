Feature: ValidateRangeRate
	In order to make sure the RangeRate calculation is implemented correctly
	As a domain expert
	I want to validate the results of the example data set to the actual calculations of the functions

Scenario: Validate RangeRate BSM sample data set against calculation
	Given the following BSM sample data set
	| HV_Time | HV_Latitude | HV_Longitude | RV_Latitude | RV_Longitude | Range  | RangeRate |
	| 1       | 42.29249    | -83.7361     | 42.29213    | -83.7364     | 47.034 | NaN       |
	| 2       | 42.29247    | -83.7361     | 42.29212    | -83.7364     | 46.093 | NaN       |
	| 3       | 42.29247    | -83.7361     | 42.29211    | -83.7364     | 47.034 | NaN       |
	| 4       | 42.29245    | -83.7361     | 42.29211    | -83.7364     | 45.16  | -10.77    |
	| 5       | 42.29245    | -83.7361     | 42.29208    | -83.7365     | 52.713 | 45.35     |
	| 6       | 42.29242    | -83.7362     | 42.29207    | -83.7365     | 46.093 | -26.02    |
	| 7       | 42.29241    | -83.7362     | 42.29207    | -83.7365     | 45.16  | -15.06    |
	| 8       | 42.29239    | -83.7362     | 42.29205    | -83.7365     | 45.16  | -8.95     |
	| 9       | 42.29238    | -83.7362     | 42.29204    | -83.7365     | 45.16  | -0.93     |
	| 10      | 42.29237    | -83.7362     | 42.29203    | -83.7365     | 45.16  | 0.00      |
	| 11      | 42.29235    | -83.7362     | 42.29202    | -83.7365     | 44.234 | -6.02     |
	| 12      | 42.29234    | -83.7362     | 42.29201    | -83.7365     | 44.234 | -2.31     |
	| 13      | 42.29232    | -83.7362     | 42.292      | -83.7365     | 43.318 | -6.88     |
	When I calculate the Range and RangeRate
	Then the results within the data set should match with the calculated results


Scenario: Validate RangeRate BSM sample data set against calculation - Using real data
	Given the following BSM sample data set
	| HV_Time | HV_Latitude | HV_Longitude | RV_Latitude | RV_Longitude | Range  | RangeRate |
	| 1       | 41.1503639221191 | -104.657737731934 | 41.15212631 | -104.6603699 | 295.06 | NaN       |
	| 2       | 41.1503639221191 | -104.657737731934 | 41.15209961 | -104.6603546 | 292.14 | NaN       |
	| 3       | 41.1503639221191 | -104.657737731934 | 41.15208817 | -104.660347  | 290.82 | NaN       |
	| 4       | 41.1503639221191 | -104.657737731934 | 41.15207672 | -104.6603394 | 289.51 | -14.76    |
	| 5       | 41.1503639221191 | -104.657737731934 | 41.15206909 | -104.6603317 | 288.46 | -11.38    |
	When I calculate the Range and RangeRate
	Then the results within the data set should match with the calculated results

