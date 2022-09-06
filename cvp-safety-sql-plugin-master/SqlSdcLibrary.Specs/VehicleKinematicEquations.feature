Feature: VehicleKinematicEquations
	as a developer and domain level expert
	I want to be make sure the Vehicle kinematic equations are implemented correctly

Scenario: chapter 2.6.01. calculating Northing and Easting based on Latitude and Longitude
	Given vehicles
	| VehicleId | Latitude  | Longitude  | Projection |
	| 1         | 37.81945  | -122.34544 | 4326       |
	| 2         | 37.81971  | -122.34355 | 4326       |
	| 3         | 42.292488 | -83.736084 | 4326       |
	| 4         | 42.292126 | -83.736412 | 4326       |
	When calculating Northing and Easting
	Then the result should be
	| VehicleId | Northing   | Easting   | Zona |
	| 1         | 4185984.71 | 557609.54 | 10S  |
	| 2         | 4186014.72 | 557775.68 | 10S  |
	| 3         | 4685877.26 | 274436.43 | 17T  |
	| 4         | 4685837.93 | 274408.09 | 17T  |

Scenario: chapter 2.6.01. calculating NorthOffset and EastOffset between two vehicles
	Given vehicles
	| VehicleId | Latitude  | Longitude  | Projection |
	| 1         | 37.81945  | -122.34544 | 4326       |
	| 2         | 37.81971  | -122.34355 | 4326       |
	| 3         | 42.292488 | -83.736084 | 4326       |
	| 4         | 42.292126 | -83.736412 | 4326       |
	And the following vehicles are associated with one-another
	| LinkId | HostVehicleId | RemoteVehicleId |
	| 1      | 1             | 2               |
	| 2      | 3             | 4               |
	When calculating NorthOffset and EastOffset
	Then the result for northOffset and EastOffset should be
	| LinkId | NorthOffset | EastOffset |
	| 1      | 30.014      | 166.143    |
	| 2      | -39.329     | -28.335    |

Scenario: chapter 2.6.01. calculating Range
	Given vehicles
	| VehicleId | Latitude  | Longitude  | Projection |
	| 1         | 37.81945  | -122.34544 | 4326       |
	| 2         | 37.81971  | -122.34355 | 4326       |
	| 3         | 42.292488 | -83.736084 | 4326       |
	| 4         | 42.292126 | -83.736412 | 4326       |
	And the following vehicles are associated with one-another
	| LinkId | HostVehicleId | RemoteVehicleId |
	| 1      | 1             | 2               |  
	| 2      | 3             | 4               |
	When calculating Range
	Then the range should be
	| LinkId | Range  |
	| 1      | 168.83 |
	| 2      | 48.47  |

Scenario: chapter 2.6.02. calculating Range Rate
	Given an ScaledDRange time serie
	| ScaledDRangeId | Range1 | Range2 | Range3 | Range4 |
	| 1              | 350    | 500    | 750    | 900    |
	| 2              | 350    | 500    | 750    | 900    |
	And a dT time difference between data points
	| ScaledDRangeId | dT |
	| 1              | 20 |
	| 2              | 10 |
	When calculating Range Rate
	Then the range rate result should be
	| ScaledDRangeId | RangeRate |
	| 1              | 8.75      |
	| 2              | 17.5      |

Scenario: chapter 2.6.02. calculating Range Rate for real time-serie
	Given Host vehicle with locations over time
	| PositionId | Latitude  | Longitude  | Projection |
	| 1          | 42.292488 | -83.736084 | 4326       |
	| 2          | 42.292473 | -83.736099 | 4326       |
	| 3          | 42.292473 | -83.736099 | 4326       |
	| 4          | 42.292446 | -83.73613  | 4326       |
	Given Remote vehicle with locations over time
	| PositionId | Latitude  | Longitude  | Projection |
	| 1          | 42.292126 | -83.736412 | 4326       |
	| 2          | 42.292118 | -83.736427 | 4326       |
	| 3          | 42.292107 | -83.736435 | 4326       |
	| 4          | 42.292107 | -83.736435 | 4326       |
	And dt is 100
	When calculating Range Rate for vehicles
	Then the Range Rate should be -0.0226

Scenario: chapter 2.6.03. calculating Time-to-Collision (TTC) in seconds
	Given a Range and RangeRate
	| Id | Range              | RangeRate |
	| 1  | 48.473431953926465 | -0.0226   |
	| 2  | 47.830103223411768 | -0.0226   |
	| 3  | 49.211435846626948 | -0.0226   |
	| 4  | 45.294413802431613 | -0.0226   |
	When calculating Time-to-Collision
	Then the Time-to-collision result should be
	| Id | TimeToCollision |
	| 1  | -2144.842       |
	| 2  | -2116.376       |
	| 3  | -2177.497       |
	| 4  | -2004.177       |

Scenario: chapter 2.6.04. Calculate HVSlope
	Given the following heading
	| Id | Heading |
	| 1  | 45      |
	| 2  | 135     |
	| 3  | 215     |
	| 4  | 315     |
	| 5  | 50      |
	When calculating the HVSlope
	Then the HVSlope result should be
	| Id | Slope |
	| 1  | 1     |
	| 2  | -1    |
	| 3  | 1.42  |
	| 4  | -0.99 |
	| 5  | 0.83  |

Scenario: chapter 2.6.04. calculating Longitudinal Range
	Given vehicles
	| VehicleId | Latitude  | Longitude  | Projection |
	| 1         | 37.81945  | -122.34544 | 4326       |
	| 2         | 37.81971  | -122.34355 | 4326       |
	| 3         | 42.292488 | -83.736084 | 4326       |
	| 4         | 42.292126 | -83.736412 | 4326       |
	And the following vehicles are associated with one-another
	| LinkId | HostVehicleId | RemoteVehicleId |
	| 1      | 1             | 2               |
	| 2      | 3             | 4               |
	And Heading of
	| VehicleId | Heading |
	| 1         | 66      |
	| 3         | 217.0   |
	When calculating the Longitudinal Range
	Then the Longitudinal Range results should be
	| LinkId | LongRange |
	| 1      | 163.987   |
	| 2      | 48.462    |

Scenario: chapter 2.6.04. calculating Latitudinal Range
	Given vehicles
	| VehicleId | Latitude  | Longitude  | Projection |
	| 1         | 37.81945  | -122.34544 | 4326       |
	| 2         | 37.81971  | -122.34355 | 4326       |
	| 3         | 42.292488 | -83.736084 | 4326       |
	| 4         | 42.292126 | -83.736412 | 4326       |
	And the following vehicles are associated with one-another
	| LinkId | HostVehicleId | RemoteVehicleId |
	| 1      | 1             | 2               |
	| 2      | 3             | 4               |
	And Heading of
	| VehicleId | Heading |
	| 1         | 66      |
	| 3         | 217.0   |
	When calculating the Latitudinal Range
	Then the Latitudinal Range should be
	| LinkId | LatRange |
	| 1      | 40.157   |
	| 2      | -1.039   |

Scenario: chapter 2.6.05. Relative Latitudinal and Longitudinal Positions
	Given vehicles
	| VehicleId | Latitude  | Longitude  | Projection |
	| 1         | 37.81945  | -122.34544 | 4326       |
	| 2         | 37.81971  | -122.34355 | 4326       |
	| 3         | 42.292488 | -83.736084 | 4326       |
	| 4         | 42.292126 | -83.736412 | 4326       |
	And car length and width
	| VehicleId | Length | Width |
	| 1         | 3.50   | 3.50  |
	| 2         | 3.50   | 3.50  |
	| 3         | 3.50   | 3.50  |
	| 4         | 3.50   | 3.50  |
	And the following vehicles are associated with one-another
	| LinkId | HostVehicleId | RemoteVehicleId |
	| 1      | 1             | 2               |
	| 2      | 3             | 4               |
	And Heading of
	| VehicleId | Heading |
	| 1         | 60      |
	| 3         | 217.0   |
	When calculating the Relative Latitudinal and Longitudinal Positions
	Then the Relative Latitudinal and Longitudinal Positions results should be
	| LinkId | RelativeLongLocation | RelativeLatLocation |
	| 1      | Front                | Right               |
	| 2      | Front                | Center              |

Scenario: chapter 2.6.06. Precise Relative Location
	Given vehicles
	| VehicleId | Latitude  | Longitude  | Projection |
	| 1         | 42.292488 | -83.736084 | 4326       |
	| 2         | 42.292126 | -83.736412 | 4326       |
	And car length and width
	| VehicleId | Length | Width |
	| 1         | 3.50   | 3.50  |
	| 2         | 3.50   | 3.50  |
	And the following vehicles are associated with one-another
	| LinkId | HostVehicleId | RemoteVehicleId |
	| 1      | 1             | 2               |
	And Heading of
	| VehicleId | Heading |
	| 1         | 217.0   |
	| 2         | 212.8   |
	When calculating the Precise Relative Location
	Then the Precise Relative Location results should be
	| LinkId | PreciseRelativeLocation |
	| 1      | FcwEeblInPathTarget     |

Scenario: chapter 2.6.11. Distance to Point of Interest
	Given two points
	| PointId | Latitude  | Longitude  | Projection |
	| 1       | 42.292488 | -83.736084 | 4326       |
	| 2       | 42.292126 | -83.736412 | 4326       |
	When calculating the Distance to Point of Interest
	Then the Distance to Point of Interest should be 48.392
