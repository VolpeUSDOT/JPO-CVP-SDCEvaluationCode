using System;
using System.Collections;
using System.Data.SqlTypes;
using System.Reflection;
using System.Xml.Linq;
using Microsoft.SqlServer.Server;
using Microsoft.SqlServer.Types;

namespace SqlSdcLibrary
{
    public class SqlFunctions
    {
        [SqlFunction(DataAccess = DataAccessKind.None)]
        public static SqlString SqlClrDllVersion()
        {
            return Assembly.GetExecutingAssembly().GetName().Version.ToString();
        }

        public static void GetUtm(object obj, out SqlDouble northing, out SqlDouble easting, out SqlString zona)
        {
            northing = 0;
            easting = 0;
            zona = String.Empty;

            if (obj is SqlGeography point)
            {
                var result = Functions.ConvertToUtm(point);

                northing = result.Northing;
                easting = result.Easting;
                zona = result.Zona;
            }
        }

        [SqlFunction(FillRowMethodName = "GetUtm")]
        public static IEnumerable ToUtm(SqlGeography point)
        {
            yield return point;
        }

        [SqlFunction(DataAccess = DataAccessKind.None)]
        public static SqlDouble Northing(SqlGeography point)
        {
            if (point == null || point.IsNull)
            {
                return SqlDouble.Null;
            }

            return Functions.ConvertToUtm(point).Northing;
        }

        [SqlFunction(DataAccess = DataAccessKind.None)]
        public static SqlDouble Easting(SqlGeography point)
        {
            if (point == null || point.IsNull)
            {
                return SqlDouble.Null;
            }

            return Functions.ConvertToUtm(point).Easting;
        }

        [SqlFunction(DataAccess = DataAccessKind.None)]
        public static SqlDouble NorthOffset(SqlGeography pointRemoteVehicle, SqlGeography pointHostVehicle)
        {
            if (pointRemoteVehicle == null || pointRemoteVehicle.IsNull || pointHostVehicle == null || pointHostVehicle.IsNull)
            {
                return SqlDouble.Null;
            }

            var utmRemoveVehicle = Functions.ConvertToUtm(pointRemoteVehicle);
            var utmHostVehicle = Functions.ConvertToUtm(pointHostVehicle);

            return Functions.Offset(utmRemoveVehicle.Northing, utmHostVehicle.Northing);
        }

        [SqlFunction(DataAccess = DataAccessKind.None)]
        public static SqlDouble EastOffset(SqlGeography pointRemoteVehicle, SqlGeography pointHostVehicle)
        {
            if (pointRemoteVehicle == null || pointRemoteVehicle.IsNull || pointHostVehicle == null || pointHostVehicle.IsNull)
            {
                return SqlDouble.Null;
            }

            var utmRemoveVehicle = Functions.ConvertToUtm(pointRemoteVehicle);
            var utmHostVehicle = Functions.ConvertToUtm(pointHostVehicle);

            return Functions.Offset(utmRemoveVehicle.Easting, utmHostVehicle.Easting);
        }

        [SqlFunction(DataAccess = DataAccessKind.None)]
        public static SqlDouble Range(SqlGeography pointRemoteVehicle, SqlGeography pointHostVehicle)
        {
            if (pointRemoteVehicle == null || pointHostVehicle == null || pointRemoteVehicle.IsNull || pointHostVehicle.IsNull)
            {
                return SqlDouble.Null;
            }

            var northOffset = NorthOffset(pointRemoteVehicle, pointHostVehicle);
            var eastOffset = EastOffset(pointRemoteVehicle, pointHostVehicle);

            return Functions.Range(northOffset.Value, eastOffset.Value);
        }

        [SqlFunction(DataAccess = DataAccessKind.None)]
        public static SqlDouble RangeRate(SqlDouble scaledDRange, SqlDouble dt)
        {
            if (scaledDRange.IsNull || dt.IsNull || dt.Value == 0)
            {
                return SqlDouble.Null;
            }

            return Functions.RangeRate(scaledDRange.Value, dt.Value);
        }

        [SqlFunction(DataAccess = DataAccessKind.None)]
        public static SqlDouble TimeToCollision(SqlDouble range, SqlDouble rangeRate)
        {
            if (range.IsNull || rangeRate.IsNull || range.Value == null || rangeRate.Value == null || rangeRate.Value == 0)
            {
                return SqlDouble.Null;
            }

            return Functions.TimeToCollision(range.Value, rangeRate.Value);
        }

        [SqlFunction(DataAccess = DataAccessKind.None)]
        public static SqlDouble LongRange(SqlDouble northOffset, SqlDouble eastOffset, SqlDouble hostHeading)
        {
            if (northOffset.IsNull || eastOffset.IsNull || hostHeading.IsNull || northOffset.Value == null || eastOffset.Value == null || hostHeading.Value == null)
            {
                return SqlDouble.Null;
            }

            return Functions.LongRange(northOffset.Value, eastOffset.Value, hostHeading.Value);
        }

        [SqlFunction(DataAccess = DataAccessKind.None)]
        public static SqlDouble LatRange(SqlDouble range, SqlDouble longRange, SqlDouble northOffset, SqlDouble eastOffset, SqlDouble hostHeading)
        {
            if (range.IsNull || longRange.IsNull || northOffset.IsNull || eastOffset.IsNull || hostHeading.IsNull ||
                range.Value == null || longRange.Value == null || northOffset.Value == null || eastOffset.Value == null || hostHeading.Value == null)
            {
                return SqlDouble.Null;
            }

            return Functions.LatRange(range.Value, longRange.Value, northOffset.Value, eastOffset.Value, hostHeading.Value);
        }

        [SqlFunction(DataAccess = DataAccessKind.None)]
        public static SqlString RelLongRange(SqlDouble longRange, SqlDouble hvLength, SqlDouble rvLength)
        {
            if (longRange.IsNull || hvLength.IsNull || rvLength.IsNull ||
                longRange.Value == null || hvLength.Value == null || rvLength.Value == null)
            {
                return SqlString.Null;
            }

            return Functions.RelLongRange(longRange.Value, hvLength.Value, rvLength.Value).ToString();
        }

        [SqlFunction(DataAccess = DataAccessKind.None)]
        public static SqlString RelLatRange(SqlDouble latRange, SqlDouble hvWidth, SqlDouble rvWidth)
        {
            if (latRange.IsNull || hvWidth.IsNull || rvWidth.IsNull ||
                latRange.Value == null || hvWidth.Value == null || rvWidth.Value == null)
            {
                return SqlString.Null;
            }

            return Functions.RelLatRange(latRange.Value, hvWidth.Value, rvWidth.Value).ToString();
        }

        [SqlFunction(DataAccess = DataAccessKind.None)]
        public static SqlString PreciseRelativeLocation(
            SqlDouble hvHeading,
            SqlDouble rvHeading,
            SqlString relativeLongLocation,
            SqlString relativeLatLocation,
            SqlDouble hvLength,
            SqlDouble hvWidth,
            SqlDouble rvLength,
            SqlDouble rvWidth,
            SqlDouble longRange,
            SqlDouble latRange)

        {
            if (hvHeading.IsNull || rvHeading.IsNull || hvLength.IsNull || hvWidth.IsNull || rvLength.IsNull || rvWidth.IsNull || longRange.IsNull || latRange.IsNull ||
                hvHeading.Value == null || rvHeading.Value == null || hvLength.Value == null || hvWidth.Value == null || rvLength.Value == null || rvWidth.Value == null || longRange.Value == null || latRange.Value == null)
            {
                return SqlString.Null;
            }

            if (relativeLongLocation.IsNull || relativeLatLocation.IsNull)
            {
                return SqlString.Null;
            }

            if (!Enum.TryParse(relativeLongLocation.Value, true, out Functions.RelativeLongLocation resultRelLongLocation))
            {
                return SqlString.Null;
            }

            if (!Enum.TryParse(relativeLatLocation.Value, true, out Functions.RelativeLatLocation resultRelLatLocation))
            {
                return SqlString.Null;
            }

            try
            {
                return Functions.RvPreciseRelativeLocation(hvHeading.Value, rvHeading.Value, resultRelLongLocation,
                    resultRelLatLocation, hvLength.Value, hvWidth.Value, rvLength.Value, rvWidth.Value, longRange.Value,
                    latRange.Value).ToString();
            }
            catch
            {
                return SqlString.Null;
            }
        }

        [SqlFunction(DataAccess = DataAccessKind.None)]
        public static SqlDouble TimeToIntersection(SqlDouble range, SqlDouble speed)
        {
            if (range.IsNull || speed.IsNull ||
                range.Value == null || speed.Value == null ||
                speed.Value == 0)
            {
                return SqlDouble.Null;
            }

            return Functions.TimeToIntersection(range.Value, speed.Value);
        }

        [SqlFunction(DataAccess = DataAccessKind.None)]
        public static SqlDouble HVSlope(SqlDouble hostHeading)
        {
            if (hostHeading.IsNull ||
                hostHeading.Value == null)
            {
                return SqlDouble.Null;
            }

            try
            {
                return Functions.HVSlope(hostHeading.Value);
            }
            catch
            {
                return SqlDouble.Null;
            }
        }

        [SqlFunction(DataAccess = DataAccessKind.None)]
        public static SqlDouble RVSlope(SqlDouble hvSlope)
        {
            if (hvSlope.IsNull ||
                hvSlope.Value == null ||
                hvSlope.Value == 0)
            {
                return SqlDouble.Null;
            }

            try
            {
                return Functions.RVSlope(hvSlope.Value);
            }
            catch
            {
                return SqlDouble.Null;
            }
        }

        [SqlFunction(DataAccess = DataAccessKind.None)]
        public static SqlDouble CalculateB(SqlDouble northOffset, SqlDouble eastOffset, SqlDouble hvSlope)
        {
            if (northOffset.IsNull || eastOffset.IsNull || hvSlope.IsNull ||
                northOffset.Value == null || eastOffset.Value == null || hvSlope.Value == null ||
                hvSlope.Value == 0)
            {
                return SqlDouble.Null;
            }

            try
            {
                return Functions.CalculateB(northOffset.Value, eastOffset.Value, hvSlope.Value);
            }
            catch
            {
                return SqlDouble.Null;
            }
        }

        [SqlFunction(DataAccess = DataAccessKind.None)]
        public static SqlDouble CalculateX(SqlDouble b, SqlDouble hvSlope, SqlDouble rvSlope)
        {
            if (b.IsNull || hvSlope.IsNull || rvSlope.IsNull ||
                b.Value == null || hvSlope.Value == null || rvSlope.Value == null)
            {
                return SqlDouble.Null;
            }

            try
            {
                return Functions.CalculateX(b.Value, hvSlope.Value, rvSlope.Value);
            }
            catch
            {
                return SqlDouble.Null;
            }
        }

        [SqlFunction(DataAccess = DataAccessKind.None)]
        public static SqlDouble CalculateY(SqlDouble hvSlope, SqlDouble x)
        {
            if (hvSlope.IsNull || x.IsNull ||
                hvSlope.Value == null || x.Value == null)
            {
                return SqlDouble.Null;
            }

            return Functions.CalculateY(hvSlope.Value, x.Value);
        }

        [SqlFunction(DataAccess = DataAccessKind.None)]
        public static SqlDouble HVTTIBasedOnDtI(SqlDouble x, SqlDouble y, SqlDouble hvSpeed)
        {
            if (x.IsNull || y.IsNull || hvSpeed.IsNull ||
                x.Value == null || y.Value == null || hvSpeed.Value == null)
            {
                return SqlDouble.Null;
            }

            try
            {
                return Functions.HostVehicleTimeToIntersectionBasedOnDistanceToIntersection(x.Value, y.Value,
                    hvSpeed.Value);
            }
            catch
            {
                return SqlDouble.Null;
            }
        }

        [SqlFunction(DataAccess = DataAccessKind.None)]
        public static SqlDouble RVTTIBasedOnDtI(SqlDouble eastOffset, SqlDouble x, SqlDouble northOffset, SqlDouble y, SqlDouble rvSpeed)
        {
            if (eastOffset.IsNull || x.IsNull || northOffset.IsNull || y.IsNull || rvSpeed.IsNull ||
                eastOffset.Value == null || x.Value == null || northOffset.Value == null || y.Value == null || rvSpeed.Value == null)
            {
                return SqlDouble.Null;
            }

            try
            {
                return Functions.RemoveVehicleTimeToIntersectionBasedOnDistanceToIntersection(eastOffset.Value, x.Value, northOffset.Value, y.Value, rvSpeed.Value);
            }
            catch
            {
                return SqlDouble.Null;
            }
        }

        [SqlFunction(DataAccess = DataAccessKind.None)]
        public static SqlDouble DistanceToPointOfInterestInMeters(SqlDouble hvLatitude, SqlDouble hvLongitude,
            SqlDouble xxLatitude, SqlDouble xxLongitude)
        {
            if (hvLatitude.IsNull || hvLongitude.IsNull || xxLatitude.IsNull || xxLongitude.IsNull ||
                hvLatitude.Value == null || hvLongitude.Value == null || xxLatitude.Value == null ||
                xxLongitude.Value == null)
            {
                return SqlDouble.Null;
            }

            try
            {
                return Functions.DistanceToPointOfInterestInMeters(hvLatitude.Value, hvLongitude.Value,
                    xxLatitude.Value, xxLongitude.Value);
            }
            catch
            {
                return SqlDouble.Null;
            }
        }

        [SqlFunction(DataAccess = DataAccessKind.None)]
        public static SqlDouble TimeToPointOfInterest(SqlDouble distance, SqlDouble speed)
        {
            if (distance.IsNull || speed.IsNull ||
                distance.Value == null || speed.Value == null ||
                speed.Value == 0)
            {
                return SqlDouble.Null;
            }

            try
            {
                return Functions.TimeToPointOfInterest(distance.Value, speed.Value);
            }
            catch
            {
                return SqlDouble.Null;
            }
        }
    }
}
