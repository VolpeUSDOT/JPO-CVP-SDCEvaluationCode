using System.Data.SqlTypes;
using FluentAssertions;
using Microsoft.SqlServer.Types;
using NUnit.Framework;

namespace SqlSdcLibrary.Test
{
    [TestFixture]
    public class SqlFunctionsUnitTests
    {
        [Test]
        public void Validate_Version()
        {
            SqlFunctions.SqlClrDllVersion().Value.Should().Be("2.0.0.0");
        }

        [Test]
        public void Validate_ToUtm()
        {
            var latitude = 42.212322;
            var longitude = -71.122213;

            var pointHostVehicle = SqlGeography.Point(latitude, longitude, 4326);
            var utm = SqlFunctions.ToUtm(pointHostVehicle);

            utm.Should().NotBeNull();
            utm.Should().HaveCount(1);
            foreach (var item in utm)
            {
                item.Should().BeOfType<SqlGeography>();
                ((SqlGeography) item).Lat.Value.Should().Be(latitude);
                ((SqlGeography) item).Long.Value.Should().Be(longitude);
            }
        }

        [Test]
        public void Validate_GetUtm_Northing_test_with_specific_value()
        {
            var point = SqlGeography.Point(41.1503639221191, -104.657737731934, 4326);
            SqlFunctions.GetUtm(point, out var northing, out var easting, out var zona);
            northing.Value.Should().BeApproximately(4555505.54830884, 0.0000001);
        }

        [Test]
        public void Validate_GetUtm()
        {
            var point = SqlGeography.Point(42.387684, -71.180236, 4326);
            SqlFunctions.GetUtm(point, out var northing, out var easting, out var zona);
            northing.Value.Should().BeApproximately(4695124.27, 0.01);
            easting.Value.Should().BeApproximately(320534.15, 0.01);
            zona.Value.Should().Be("19T");
        }

        [Test]
        public void Validate_Northing()
        {
            SqlFunctions.Northing(SqlGeography.Null).Should().Be(SqlDouble.Null);
            SqlFunctions.Northing(null).Should().Be(SqlDouble.Null);

            var point = SqlGeography.Point(42.387684, -71.180236, 4326);
            SqlFunctions.Northing(point).Value.Should().BeApproximately(4695124.27, 0.01);
        }

        [Test]
        public void Validate_Easting()
        {
            SqlFunctions.Easting(SqlGeography.Null).Should().Be(SqlDouble.Null);
            SqlFunctions.Easting(null).Should().Be(SqlDouble.Null);

            var point = SqlGeography.Point(42.387684, -71.180236, 4326);
            SqlFunctions.Easting(point).Value.Should().BeApproximately(320534.15, 0.01);
        }

        [Test]
        public void Validate_NorthOffset()
        {
            var pointRemoteVehicle = SqlGeography.Point(42.387684, -71.180236, 4326);
            var pointHostVehicle = SqlGeography.Point(42.212322, -71.122213, 4326);
            var northOffset = SqlFunctions.NorthOffset(pointRemoteVehicle, pointHostVehicle);
            northOffset.Value.Should().BeApproximately(19593.49, 0.01);

            SqlFunctions.NorthOffset(SqlGeography.Null, pointHostVehicle).Should().Be(SqlDouble.Null);
            SqlFunctions.NorthOffset(pointRemoteVehicle, SqlGeography.Null).Should().Be(SqlDouble.Null);
            SqlFunctions.NorthOffset(null, pointHostVehicle).Should().Be(SqlDouble.Null);
            SqlFunctions.NorthOffset(pointRemoteVehicle, null).Should().Be(SqlDouble.Null);
        }

        [Test]
        public void Validate_EastOffset()
        {
            var pointRemoteVehicle = SqlGeography.Point(42.387684, -71.180236, 4326);
            var pointHostVehicle = SqlGeography.Point(42.212322, -71.122213, 4326);
            var eastOffset = SqlFunctions.EastOffset(pointRemoteVehicle, pointHostVehicle);
            eastOffset.Value.Should().BeApproximately(-4290.72, 0.01);

            SqlFunctions.EastOffset(SqlGeography.Null, pointHostVehicle).Should().Be(SqlDouble.Null);
            SqlFunctions.EastOffset(pointRemoteVehicle, SqlGeography.Null).Should().Be(SqlDouble.Null);
            SqlFunctions.EastOffset(null, pointHostVehicle).Should().Be(SqlDouble.Null);
            SqlFunctions.EastOffset(pointRemoteVehicle, null).Should().Be(SqlDouble.Null);
        }

        [Test]
        public void Validate_Range()
        {
            var pointRemoteVehicle = SqlGeography.Point(42.387684, -71.180236, 4326);
            var pointHostVehicle = SqlGeography.Point(42.212322, -71.122213, 4326);

            var range = SqlFunctions.Range(pointRemoteVehicle, pointHostVehicle);
            range.Value.Should().BeApproximately(20057.80, 0.01);
        }

        [Test]
        public void Validate_Range_handle_null()
        {
            var pointRemoteVehicle = SqlGeography.Point(42.387684, -71.180236, 4326);
            var pointHostVehicle = SqlGeography.Point(42.212322, -71.122213, 4326);

            var range = SqlFunctions.Range(null, pointHostVehicle);
            range.Should().Be(SqlDouble.Null);

            range = SqlFunctions.Range(pointRemoteVehicle, null);
            range.Should().Be(SqlDouble.Null);

            range = SqlFunctions.Range(null, null);
            range.Should().Be(SqlDouble.Null);

            range = SqlFunctions.Range(SqlGeography.Null, pointHostVehicle);
            range.Should().Be(SqlDouble.Null);

            range = SqlFunctions.Range(pointRemoteVehicle, SqlGeography.Null);
            range.Should().Be(SqlDouble.Null);

            range = SqlFunctions.Range(SqlGeography.Null, SqlGeography.Null);
            range.Should().Be(SqlDouble.Null);
        }

        [Test]
        public void Validate_RangeRate()
        {
            var rangeRate = SqlFunctions.RangeRate(new SqlDouble(-100), new SqlDouble(10));
            rangeRate.Value.Should().Be(-10);

            rangeRate = SqlFunctions.RangeRate(new SqlDouble(0), new SqlDouble(10));
            rangeRate.Value.Should().Be(0);
        }

        [Test]
        public void Validate_RangeRate_handle_null_and_division_by_zero()
        {
            var dt = new SqlDouble();
            var rangeRate = SqlFunctions.RangeRate(new SqlDouble(-100), dt);
            rangeRate.Should().Be(SqlDouble.Null);

            rangeRate = SqlFunctions.RangeRate(new SqlDouble(-100), SqlDouble.Null);
            rangeRate.Should().Be(SqlDouble.Null);

            rangeRate = SqlFunctions.RangeRate(new SqlDouble(-100), new SqlDouble(0));
            rangeRate.Should().Be(SqlDouble.Null);

            rangeRate = SqlFunctions.RangeRate(SqlDouble.Null, new SqlDouble(0));
            rangeRate.Should().Be(SqlDouble.Null);
        }

        [Test]
        public void Validate_TimeToCollision()
        {
            var range = SqlFunctions.TimeToCollision(new SqlDouble(-100), new SqlDouble(20));
            range.Value.Should().Be(-5);
        }

        [Test]
        public void Validate_TimeToCollision_handle_null_and_division_by_zero()
        {
            SqlFunctions.TimeToCollision(SqlDouble.Null, new SqlDouble(20)).Should().Be(SqlDouble.Null);
            SqlFunctions.TimeToCollision(new SqlDouble(-100), SqlDouble.Null).Should().Be(SqlDouble.Null);
            SqlFunctions.TimeToCollision(new SqlDouble(-100), new SqlDouble(0)).Should().Be(SqlDouble.Null);
        }

        [Test]
        public void Validate_LongRange()
        {
            var northOffset = 100;
            var eastOffset = 20;
            var heading = 80;
            var range = SqlFunctions.LongRange(new SqlDouble(northOffset), new SqlDouble(eastOffset),
                new SqlDouble(heading));
            range.Value.Should().BeApproximately(37.06, 0.01);
        }

        [Test]
        public void Validate_LongRange_at_specific_heading()
        {
            var northOffset = 100;
            var eastOffset = 20;
            var heading = 0;
            var range = SqlFunctions.LongRange(new SqlDouble(northOffset), new SqlDouble(eastOffset),
                new SqlDouble(heading));
            range.Value.Should().Be(northOffset);

            northOffset = 100;
            eastOffset = 20;
            heading = 180;
            range = SqlFunctions.LongRange(new SqlDouble(northOffset), new SqlDouble(eastOffset),
                new SqlDouble(heading));
            range.Value.Should().Be(northOffset);

            northOffset = 100;
            eastOffset = 20;
            heading = 90;
            range = SqlFunctions.LongRange(new SqlDouble(northOffset), new SqlDouble(eastOffset),
                new SqlDouble(heading));
            range.Value.Should().Be(eastOffset);

            northOffset = 100;
            eastOffset = 20;
            heading = 270;
            range = SqlFunctions.LongRange(new SqlDouble(northOffset), new SqlDouble(eastOffset),
                new SqlDouble(heading));
            range.Value.Should().Be(eastOffset);
        }

        [Test]
        public void Validate_LongRange_handle_null_and_division_by_zero()
        {
            var northOffset = 100;
            var eastOffset = 20;
            var heading = 0;

            var range = SqlFunctions.LongRange(new SqlDouble(northOffset), SqlDouble.Null, new SqlDouble(heading));
            range.Should().Be(SqlDouble.Null);

            range = SqlFunctions.LongRange(SqlDouble.Null, new SqlDouble(eastOffset), new SqlDouble(heading));
            range.Should().Be(SqlDouble.Null);

            range = SqlFunctions.LongRange(new SqlDouble(northOffset), new SqlDouble(eastOffset), SqlDouble.Null);
            range.Should().Be(SqlDouble.Null);
        }


        [Test]
        public void Validate_LatRange()
        {
            var northOffset = 100;
            var eastOffset = 20;
            var hostHeading = 80;
            var range = Functions.Range(northOffset, eastOffset);
            var longRange = Functions.LongRange(northOffset, eastOffset, hostHeading);

            var latRange = SqlFunctions.LatRange(new SqlDouble(range), new SqlDouble(longRange),
                new SqlDouble(northOffset), new SqlDouble(eastOffset), new SqlDouble(hostHeading));
            latRange.Value.Should().BeApproximately(-95.00781174788, 0.01);
        }

        [Test]
        public void Validate_LatRange_at_specific_heading()
        {
            var northOffset = 100;
            var eastOffset = 20;
            var hostHeading = 0;
            var range = Functions.Range(northOffset, eastOffset);
            var longRange = Functions.LongRange(northOffset, eastOffset, hostHeading);

            var latRange = SqlFunctions.LatRange(new SqlDouble(range), new SqlDouble(longRange),
                new SqlDouble(northOffset), new SqlDouble(eastOffset), new SqlDouble(hostHeading));
            latRange.Value.Should().Be(eastOffset);

            northOffset = 100;
            eastOffset = 80;
            hostHeading = 180;
            range = Functions.Range(northOffset, eastOffset);
            longRange = Functions.LongRange(northOffset, eastOffset, hostHeading);

            latRange = SqlFunctions.LatRange(new SqlDouble(range), new SqlDouble(longRange), new SqlDouble(northOffset),
                new SqlDouble(eastOffset), new SqlDouble(hostHeading));
            latRange.Value.Should().Be(eastOffset);

            northOffset = 100;
            eastOffset = 80;
            hostHeading = 90;
            range = Functions.Range(northOffset, eastOffset);
            longRange = Functions.LongRange(northOffset, eastOffset, hostHeading);

            latRange = SqlFunctions.LatRange(new SqlDouble(range), new SqlDouble(longRange), new SqlDouble(northOffset),
                new SqlDouble(eastOffset), new SqlDouble(hostHeading));
            latRange.Value.Should().Be(northOffset);

            northOffset = 100;
            eastOffset = 80;
            hostHeading = 270;
            range = Functions.Range(northOffset, eastOffset);
            longRange = Functions.LongRange(northOffset, eastOffset, hostHeading);

            latRange = SqlFunctions.LatRange(new SqlDouble(range), new SqlDouble(longRange), new SqlDouble(northOffset),
                new SqlDouble(eastOffset), new SqlDouble(hostHeading));
            latRange.Value.Should().Be(northOffset);
        }

        [Test]
        public void Validate_LatRange_handle_null_and_division_by_zero()
        {
            // TODO: automate NULL value checker?! ; expand test
            var northOffset = 100;
            var eastOffset = 20;
            var hostHeading = 0;
            var range = Functions.Range(northOffset, eastOffset);
            var longRange = Functions.LongRange(northOffset, eastOffset, hostHeading);

            var latRange = SqlFunctions.LatRange(new SqlDouble(range), new SqlDouble(longRange),
                new SqlDouble(northOffset), new SqlDouble(eastOffset), SqlDouble.Null);
            latRange.Should().Be(SqlDouble.Null);
        }

        [Test]
        public void Validate_RelLongRange()
        {
            SqlFunctions.RelLongRange(new SqlDouble(117.050), new SqlDouble(2.00), new SqlDouble(3.00)).Value.Should()
                .Be("Front");
            SqlFunctions.RelLongRange(new SqlDouble(-117.050), new SqlDouble(2.00), new SqlDouble(3.00)).Value.Should()
                .Be("Behind");
            SqlFunctions.RelLongRange(new SqlDouble(1.17050), new SqlDouble(2.00), new SqlDouble(3.00)).Value.Should()
                .Be("Side");
        }

        [Test]
        public void Validate_RelLatRange()
        {
            SqlFunctions.RelLatRange(new SqlDouble(117.050), new SqlDouble(2.00), new SqlDouble(3.00)).Value.Should()
                .Be("Right");
            SqlFunctions.RelLatRange(new SqlDouble(-117.050), new SqlDouble(2.00), new SqlDouble(3.00)).Value.Should()
                .Be("Left");
            SqlFunctions.RelLatRange(new SqlDouble(1.17050), new SqlDouble(2.00), new SqlDouble(3.00)).Value.Should()
                .Be("Center");
        }

        [Test]
        public void Validate_PreciseRelativeLocation()
        {
            SqlFunctions.PreciseRelativeLocation(
                new SqlDouble(119.949),
                new SqlDouble(153.537),
                new SqlString("Behind"),
                new SqlString("Left"),
                new SqlDouble(579 / 100),
                new SqlDouble(203 / 100),
                new SqlDouble(506 / 100),
                new SqlDouble(191 / 100),
                new SqlDouble(-289.275),
                new SqlDouble(-58.125)).IsNull.Should().BeTrue();

            SqlFunctions.PreciseRelativeLocation(
                new SqlDouble(40),
                new SqlDouble(130),
                new SqlString("Front"),
                new SqlString("Default"),
                new SqlDouble(-1),
                new SqlDouble(-1),
                new SqlDouble(-1),
                new SqlDouble(-1),
                new SqlDouble(-1),
                new SqlDouble(-1)).Value.Should().Be("ImaLeft");
        }

        [Test]
        public void Validate_TimeToIntersection()
        {
            SqlFunctions.TimeToIntersection(new SqlDouble(10), new SqlDouble(2)).Value.Should().Be(5);
        }

        [Test]
        public void Validate_HVSlope()
        {
            SqlFunctions.HVSlope(new SqlDouble(10)).Value.Should().BeApproximately(5.6712818196177066, 0.0001);
        }

        [Test]
        public void Validate_RVSlope()
        {
            SqlFunctions.RVSlope(new SqlDouble(10)).Value.Should().Be(-0.1);
        }

        [Test]
        public void Validate_CalculateB()
        {
            SqlFunctions.CalculateB(new SqlDouble(10), new SqlDouble(2), new SqlDouble(10)).Value.Should().Be(10.2);
        }

        [Test]
        public void Validate_CalculateX()
        {
            SqlFunctions.CalculateX(new SqlDouble(10), new SqlDouble(2), new SqlDouble(12)).Value.Should().Be(-1.0);
        }

        [Test]
        public void Validate_CalculateY()
        {
            SqlFunctions.CalculateY(new SqlDouble(10), new SqlDouble(2)).Value.Should().Be(20.0);
        }

        [Test]
        public void Validate_HVTTIBasedOnDtI()
        {
            SqlFunctions.HVTTIBasedOnDtI(new SqlDouble(10), new SqlDouble(2), new SqlDouble(3)).Value.Should().BeApproximately(3.3993463423951895, 0.00001);
        }

        [Test]
        public void Validate_RVTTIBasedOnDtI()
        {
            SqlFunctions.RVTTIBasedOnDtI(new SqlDouble(10), new SqlDouble(2), new SqlDouble(14), new SqlDouble(1), new SqlDouble(3)).Value.Should().BeApproximately(5.0881125074912488, 0.00001);
        }

        [Test]
        public void Validate_DistanceToPointOfInterestInMeters()
        {
            var lat = 41.1503639221191;
            var @long = -104.657737731934;

            var xLat = 42.12131121;
            var xLong = -104.9889793;

            SqlFunctions.DistanceToPointOfInterestInMeters(lat, @long, xLat, xLong).Value.Should().BeApproximately(111268.0681936062, 0.1);
        }

        [Test]
        public void Validate_TimeToPointOfInterest()
        {
            SqlFunctions.TimeToPointOfInterest(1231, 20).Value.Should().Be(61.55);
        }
    }
}
