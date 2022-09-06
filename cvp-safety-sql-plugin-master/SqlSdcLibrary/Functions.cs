using System;
using Microsoft.SqlServer.Types;
using SqlSdcLibrary.Utils;

// ReSharper disable RedundantAssignment
// ReSharper disable once UnusedMember.Global
namespace SqlSdcLibrary
{
    public static class Functions
    {
        private static readonly LatLngUTMConverter LatLngUtmConverter = new LatLngUTMConverter("WGS 84");

        public enum RelativeLongLocation
        {
            Default = 0,
            Behind = 1,
            Side = 2,
            Front = 3,
        }

        public enum RelativeLatLocation
        {
            Default = 0,
            Left = 1,
            Center = 2,
            Right = 3,
        }

        public enum PreciseRelativeLocation
        {
            Default = 0,
            FcwEeblInPathTarget = 1,
            ImaLeft = 2,
            ImaRight = 3,
            VtrftBlindSpotZone = 4,
        }

        public static double Offset(double remoteVehicle, double hostVehicle)
        {
            return remoteVehicle - hostVehicle;
        }

        public static double Range(double northOffset, double eastOffset)
        {
            return Math.Sqrt(Math.Pow(northOffset, 2) + Math.Pow(eastOffset, 2));
        }

        public static double ScaledDRange(double range1, double range2, double range3, double range4)
        {
            return 0.65 * (range4 - range3) +
                   0.25 * (range3 - range2) +
                   0.1 * (range2 - range1);
        }

        public static double RangeRate(double scaledRange, double dt)
        {
            return scaledRange / dt;
        }

        public static double TimeToCollision(double range, double rangeRate)
        {
            return range / rangeRate;
        }

        public static double RVSlope(double hvSlope)
        {
            return -(1 / hvSlope);
        }

        public static double CalculateB(double northOffset, double eastOffset, double hvSlope)
        {
            return northOffset + (eastOffset / hvSlope);
        }

        public static double CalculateY(double hvSlope, double x)
        {
            return hvSlope * x;
        }

        public static double CalculateX(double b, double hvSlope, double rvSlope)
        {
            return b / (hvSlope - rvSlope);
        }

        public static double LongRange(double northOffset, double eastOffset, double hostHeading)
        {
            double longRange;

            if (hostHeading == 0 || hostHeading == 180)
            {
                longRange = northOffset;
            }
            else if (hostHeading == 90 || hostHeading == 270)
            {
                longRange = eastOffset;
            }
            else
            {
                var hvSlope = HVSlope(hostHeading);
                var rvSlope = RVSlope(hvSlope);

                var b = CalculateB(northOffset, eastOffset, hvSlope);
                var x = CalculateX(b, hvSlope, rvSlope);
                var y = CalculateY(hvSlope, x);

                longRange = Math.Sqrt(Math.Pow(x, 2) + Math.Pow(y, 2));
                longRange = AdjustLongRange(longRange, hostHeading, y);
            }

            return longRange;
        }

        public static double AdjustLongRange(double longRange, double heading, double y)
        {
            if (0 < heading && heading < 90)
            {
                if (y < 0)
                {
                    longRange = -1 * longRange;
                }
            } else if (90 < heading && heading < 180)
            {
                if (y > 0)
                {
                    longRange = -1 * longRange;
                }
            } else if (180 < heading && heading < 270)
            {
                if (y > 0)
                {
                    longRange = -1 * longRange;
                }
            } else if (270 < heading && heading < 360)
            {
                if (y < 0)
                {
                    longRange = -1 * longRange;
                }
            }

            return longRange;
        }

        public static double AdjustLatRange(double latRange, double heading, double northOffset, double y)
        {
            if (0 < heading && heading < 90)
            {
                if (northOffset > y)
                {
                    latRange = -1 * latRange;
                }
            }
            else if (90 < heading && heading < 180)
            {
                if (northOffset > y)
                {
                    latRange = -1 * latRange;
                }
            }
            else if (180 < heading && heading < 270)
            {
                if (northOffset < y)
                {
                    latRange = -1 * latRange;
                }
            }
            else if (270 < heading && heading < 360)
            {
                if (northOffset < y)
                {
                    latRange = -1 * latRange;
                }
            }

            return latRange;
        }

        public static double LatRange(double range, double longRange, double northOffset, double eastOffset, double hostHeading)
        {
            double latRange;

            if (hostHeading == 0 || hostHeading == 180)
            {
                latRange = eastOffset;
            }
            else if (hostHeading == 90 || hostHeading == 270)
            {
                latRange = northOffset;
            }
            else
            {
                var hvSlope = Functions.HVSlope(hostHeading);

                var rvSlope = -(1 / hvSlope);
                var b = northOffset + (eastOffset / hvSlope);
                var x = b / (hvSlope - rvSlope);
                var y = hvSlope * x;

                var temp = Math.Pow(range, 2) - Math.Pow(longRange, 2);

                if (temp < 0)
                {
                    return double.NaN;
                }

                latRange = Math.Sqrt(temp);
                latRange = AdjustLatRange(latRange, hostHeading, northOffset, y);
            }

            return latRange;
        }

        public static RelativeLongLocation RelLongRange(double longRange, double hvLength, double rvLength)
        {
            var minLongThreshold = -(0.5 * hvLength + 0.5 * rvLength);
            var maxLongThreshold = (0.5 * hvLength + 0.5 * rvLength);

            if (longRange < minLongThreshold)
            {
                return RelativeLongLocation.Behind;
            }
            else if (minLongThreshold <= longRange && longRange <= maxLongThreshold)
            {
                return RelativeLongLocation.Side;
            }
            else if (maxLongThreshold < longRange)
            {
                return RelativeLongLocation.Front;
            }

            throw new ArgumentException();
        }

        public static RelativeLatLocation RelLatRange(double latRange, double hvWidth, double rvWidth)
        {
            var minLatThreshold = -(0.5 * hvWidth + 0.5 * rvWidth + 0.15);
            var maxLatThreshold = (0.5 * hvWidth + 0.5 * rvWidth + 0.15);

            if (latRange < minLatThreshold)
            {
                return RelativeLatLocation.Left;
            }
            else if (minLatThreshold <= latRange && latRange <= maxLatThreshold)
            {
                return RelativeLatLocation.Center;
            }
            else if (maxLatThreshold < latRange)
            {
                return RelativeLatLocation.Right;
            }

            throw new ArgumentException();
        }

        public static LatLngUTMConverter.UTMResult ConvertToUtm(SqlGeography point)
        {
            return LatLngUtmConverter.convertLatLngToUtm(point.Lat.Value, point.Long.Value);
        }

        public static double DegreeToRadian(double angle)
        {
            return Math.PI * angle / 180.0;
        }

        public static double TimeToIntersection(double range, double speed)
        {
            return range / speed;
        }

        public static double HostVehicleTimeToIntersectionBasedOnDistanceToIntersection(double x, double y, double hvSpeed)
        {
            var hvDist2X = Math.Sqrt(Math.Pow(x, 2) + Math.Pow(y, 2));
            return hvDist2X / hvSpeed;
        }

        public static double RemoveVehicleTimeToIntersectionBasedOnDistanceToIntersection(double eastOffset, double x,
            double northOffset, double y, double rvSpeed)
        {
            var rvDist2X = Math.Sqrt(Math.Pow(eastOffset - x, 2) + Math.Pow(northOffset - y, 2));
            return rvDist2X / rvSpeed;
        }

        public static PreciseRelativeLocation RvPreciseRelativeLocation(
            double hvHeading, 
            double rvHeading, 
            RelativeLongLocation relativeLongLocation, 
            RelativeLatLocation relativeLatLocation,
            double hvLength,
            double hvWidth,
            double rvLength,
            double rvWidth,
            double longRange,
            double latRange)
        {
            if (IsFcwEeblInPathTarget(hvHeading, rvHeading,
                relativeLongLocation, relativeLatLocation))
            {
                return PreciseRelativeLocation.FcwEeblInPathTarget;
            }

            if (relativeLongLocation == RelativeLongLocation.Front)
            {
                if (relativeLatLocation == RelativeLatLocation.Left && IsImaLeft(hvHeading, rvHeading))
                {
                    return PreciseRelativeLocation.ImaLeft;
                }

                if (relativeLatLocation == RelativeLatLocation.Right && IsImaRight(hvHeading, rvHeading))
                {
                    return PreciseRelativeLocation.ImaRight;
                }
            }

            if (IsBlindSpotZone(
                relativeLongLocation,
                hvLength,
                hvWidth,
                longRange,
                hvHeading,
                rvHeading,
                latRange,
                rvLength,
                rvWidth))
            {
                return PreciseRelativeLocation.VtrftBlindSpotZone;
            }

            throw new ArgumentException();
        }

        private static bool IsBlindSpotZone(
            RelativeLongLocation relativeLongPos, 
            double hvLength,
            double hvWidth,
            double longRange, 
            double hvHeading, 
            double rvHeading,
            double latRange, 
            double rvLength, 
            double rvWidth)
        {
            if (relativeLongPos == RelativeLongLocation.Side ||
                relativeLongPos == RelativeLongLocation.Behind)
            {
                var blindSpotZone = -(3 + 0.5 * hvLength);
                var width = (0.5 * hvWidth + 0.5 * rvWidth);
                var length = (0.5 * hvLength + 0.5 * rvLength);

                if (blindSpotZone < longRange)
                    if (longRange < 0)
                        if (Math.Abs(hvHeading - rvHeading) < 6)
                            if (3.2 <= Math.Abs(latRange - width))
                                if (3 <= Math.Abs(longRange - length))
                                {
                                    return true;
                                }
            }

            return false;
        }

        private static bool IsImaRight(double hvHeading, double rvHeading)
        {
            if ((0 <= hvHeading && hvHeading <= 60) &&
                (hvHeading - 120 + 360 <= rvHeading &&
                 rvHeading <= hvHeading - 60 + 360))
            {
                return true;
            }
            else if ((hvHeading > 60 && hvHeading < 120) &&
                     ((hvHeading - 120 + 360 <= rvHeading &&
                       rvHeading <= 360) || hvHeading - hvHeading <= rvHeading &&
                      rvHeading <= hvHeading - 90 + 30))
            {
                return true;
            }
            else if ((120 <= hvHeading && hvHeading <= 240) &&
                     (hvHeading - 120 <= rvHeading &&
                      rvHeading <= hvHeading - 60))
            {
                return true;
            }
            else if ((hvHeading > 240 && hvHeading < 300) &&
                     (hvHeading - 120 <= rvHeading &&
                      rvHeading <= hvHeading - 60))
            {
                return true;
            }
            else if ((300 <= hvHeading && hvHeading <= 360) &&
                     (hvHeading - 120 <= rvHeading &&
                      rvHeading <= hvHeading - 60))
            {
                return true;
            }

            return false;
        }

        private static bool IsImaLeft(double hvHeading, double rvHeading)
        {
            if ((0 <= hvHeading && hvHeading <= 60) &&
                (hvHeading + 60 <= rvHeading &&
                 rvHeading <= hvHeading + 120))
            {
                return true;
            }
            else if ((hvHeading > 60 && hvHeading < 120) &&
                     (hvHeading + 60 <= rvHeading &&
                      rvHeading <= hvHeading + 120))
            {
                return true;
            }
            else if ((120 <= hvHeading && hvHeading <= 240) &&
                     (hvHeading + 60 <= rvHeading &&
                      rvHeading <= hvHeading + 120))
            {
                return true;
            }
            else if ((hvHeading > 240 && hvHeading < 300) &&
                     (hvHeading + 60 <= rvHeading && rvHeading <= 360 ||
                      hvHeading - hvHeading <= rvHeading && rvHeading <= hvHeading - 270+30))
            {
                return true;
            }
            else if ((300 <= hvHeading && hvHeading <= 360) &&
                     (hvHeading + 60 - 360 <= rvHeading && rvHeading <= hvHeading + 120 - 360))
            {
                return true;
            }

            return false;
        }

        private static bool IsFcwEeblInPathTarget(
            double hvHeading, 
            double rvHeading,
            RelativeLongLocation relativeLongPos,
            RelativeLatLocation relativeLatPos)
        {
            return Math.Abs(hvHeading - rvHeading) < 10 &&
                   relativeLongPos == RelativeLongLocation.Front &&
                   relativeLatPos == RelativeLatLocation.Center;
        }

        public static double RadianToDegrees(double radian)
        {
            return radian * (180.0 / Math.PI);
        }

        public static double DistanceToPointOfInterestInMeters(double hvLatitude, double hvLongitude, double xxLatitude, double xxLongitude)
        {
            return 111.045 * RadianToDegrees(
                       Math.Acos(
                           Math.Cos(DegreeToRadian(hvLatitude)) * Math.Cos(DegreeToRadian(xxLatitude)) *
                           Math.Cos(DegreeToRadian(hvLongitude) - DegreeToRadian(xxLongitude)) +
                           Math.Sin(DegreeToRadian(hvLatitude)) * Math.Sin(DegreeToRadian(xxLatitude))
                       )) * 1000;
        }

        public static double TimeToPointOfInterest(double distance, double speed)
        {
            return distance / speed;
        }

        public static double HVSlope(double heading)
        {
            if (heading == 0 || heading == 180 || heading == 90 || heading == 270)
            {
                throw new ArgumentOutOfRangeException(nameof(heading) + ". Value is invalid for calculating HVSlope: " +
                                                      heading + ".");
            }

            if (0 < heading && heading < 90)
            {
                return Math.Tan(Functions.DegreeToRadian(90 - heading));
            }

            if (90 < heading && heading < 180)
            {
                return 0 - Math.Tan(Functions.DegreeToRadian(heading - 90));
            }

            if (180 < heading && heading < 270)
            {
                return Math.Tan(Functions.DegreeToRadian(270 - heading));
            }

            if (270 < heading && heading < 360)
            {
                return 0 - Math.Tan(Functions.DegreeToRadian(heading - 270));
            }

            throw new ArgumentOutOfRangeException(nameof(heading));
        }
    }
}