using System;
using FluentAssertions;
using Microsoft.SqlServer.Types;
using NUnit.Framework;
using SqlSdcLibrary.Utils;

namespace SqlSdcLibrary.Test
{
    [TestFixture]
    public class UnitTests
    {
        [Test]
        public void ValidateLatLongToUtmTest()
        {
            var latLngUtmConverter = new LatLngUTMConverter("WGS 84");
            var result = latLngUtmConverter.convertLatLngToUtm(42.387684, -71.180236);

            result.Northing.Should().BeApproximately(4695124.27, 0.01);
            result.Easting.Should().BeApproximately(320534.15, 0.01);
            result.ZoneLetter.Should().Be("T");
            result.Zona.Should().Be("19T");
            result.ZoneNumber.Should().Be(19);
        }

        [Test]
        public void Chapter2_6_01_ValidateOffset()
        {
            var offset = Functions.Offset(100, 90);
            offset.Should().BeApproximately(10, 0.01);
        }

        [Test]
        public void Chapter2_6_01_ValidateRange()
        {
            var range = Functions.Range(10, 10);
            range.Should().BeApproximately(14.142, 0.01);
        }

        [Test]
        public void Chapter2_6_01_ValidateOffsetBasedOnLatLong()
        {
            var offset = Functions.Offset(12341.12, 976.12);
            offset.Should().BeApproximately(11365.0, 0.01);
        }

        [Test]
        public void Chapter2_6_01_ValidateRangeBasedOnLatLongTest()
        {
            var northOffset = 11234.112;
            var eastOffset = 34534.8;
            var range = Functions.Range(northOffset, eastOffset);
            range.Should().BeApproximately(36316.080, 0.01);
        }

        [Test]
        public void Chapter2_6_02_ValidateScaledDRangeTest()
        {
            var scaledDRange = Functions.ScaledDRange(1, 4, 6, 8);
            scaledDRange.Should().BeApproximately(2.1, 0.01);
        }

        [Test]
        public void Chapter2_6_02_ValidateRateRangeTest()
        {
            var scaledDRange = Functions.ScaledDRange(1, 4, 6, 8);
            var dt = 1;
            var rangeRate = Functions.RangeRate(scaledDRange, dt);
            rangeRate.Should().BeApproximately(2.1, 0.01);

            dt = 2;
            rangeRate = Functions.RangeRate(scaledDRange, dt);
            rangeRate.Should().BeApproximately(1.05, 0.01);
        }

        [Test]
        public void Chapter2_6_03_ValidateTimeToCollisionTest()
        {
            var range = 1;
            double rangeRate = 2;

            var timeToCollision = Functions.RangeRate(range, rangeRate);
            timeToCollision.Should().BeApproximately(0.5, 0.01);

            rangeRate = 0.5;
            timeToCollision = Functions.RangeRate(range, rangeRate);
            timeToCollision.Should().BeApproximately(2, 0.01);
        }

        [Test]
        public void Chapter2_6_04_ValidateOutOfRangeExceptionsHVSlopeCalculation()
        {
            Action act = () => Functions.HVSlope(0);
            act.Should().Throw<ArgumentOutOfRangeException>()
                .WithMessage("*Value is invalid for calculating HVSlope:*");
            act = () => Functions.HVSlope(90);
            act.Should().Throw<ArgumentOutOfRangeException>()
                .WithMessage("*Value is invalid for calculating HVSlope:*");
            act = () => Functions.HVSlope(180);
            act.Should().Throw<ArgumentOutOfRangeException>()
                .WithMessage("*Value is invalid for calculating HVSlope:*");
            act = () => Functions.HVSlope(270);
            act.Should().Throw<ArgumentOutOfRangeException>()
                .WithMessage("*Value is invalid for calculating HVSlope:*");
            act = () => Functions.HVSlope(360);
            act.Should().Throw<ArgumentOutOfRangeException>()
                .WithMessage("*Parameter name: heading");
        }

        [Test]
        public void Chapter2_6_04_ValidateHVSlopeCalculation()
        {
            Functions.HVSlope(10).Should().BeApproximately(5.671, 0.01);
            Functions.HVSlope(100).Should().BeApproximately(-0.176, 0.01);
            Functions.HVSlope(190).Should().BeApproximately(5.671, 0.01);
            Functions.HVSlope(280).Should().BeApproximately(-0.176, 0.01);
        }

        [Test]
        public void Chapter2_6_04_ValidateLongRangeTest()
        {
            double northOffset = 100;
            double eastOffset = 200;
            double heading = 0;

            var longRange = Functions.LongRange(northOffset, eastOffset, heading);
            longRange.Should().BeApproximately(northOffset, 0.01);

            heading = 180;
            longRange = Functions.LongRange(northOffset, eastOffset, heading);
            longRange.Should().BeApproximately(northOffset, 0.01);

            heading = 90;
            longRange = Functions.LongRange(northOffset, eastOffset, heading);
            longRange.Should().BeApproximately(eastOffset, 0.01);

            heading = 270;
            longRange = Functions.LongRange(northOffset, eastOffset, heading);
            longRange.Should().BeApproximately(eastOffset, 0.01);

            heading = 5;
            longRange = Functions.LongRange(northOffset, eastOffset, heading);
            longRange.Should().BeApproximately(117.050, 0.01);
        }

        [Test]
        public void Chapter2_6_04_ValidateAdjustLongRange()
        {
            Functions.AdjustLongRange(234, 45, -1).Should().Be(-234);
            Functions.AdjustLongRange(234, 45, 1).Should().Be(234);

            Functions.AdjustLongRange(234, 135, -1).Should().Be(234);
            Functions.AdjustLongRange(234, 135, 1).Should().Be(-234);

            Functions.AdjustLongRange(234, 225, -1).Should().Be(234);
            Functions.AdjustLongRange(234, 225, 1).Should().Be(-234);

            Functions.AdjustLongRange(234, 315, -1).Should().Be(-234);
            Functions.AdjustLongRange(234, 315, 1).Should().Be(234);
        }

        [Test]
        public void Chapter2_6_04_ValidateAdjustLatRange()
        {
            Functions.AdjustLatRange(234, 45, 100, 1).Should().Be(-234);
            Functions.AdjustLatRange(234, 45, -100, 1).Should().Be(234);

            Functions.AdjustLatRange(234, 135, 100, 1).Should().Be(-234);
            Functions.AdjustLatRange(234, 135, -100, 1).Should().Be(234);

            Functions.AdjustLatRange(234, 225, 100, 1).Should().Be(234);
            Functions.AdjustLatRange(234, 225, -100, 1).Should().Be(-234);

            Functions.AdjustLatRange(234, 315, 100, 1).Should().Be(234);
            Functions.AdjustLatRange(234, 315, -100, 1).Should().Be(-234);
        }

        [Test]
        public void Chapter2_6_04_ValidateLatRangeTest()
        {
            double range = 20057.80;
            double longRange = 117.050;
            double northOffset = 100;
            double eastOffset = 200;
            double heading = 0;

            var latRange = Functions.LatRange(range, longRange, northOffset, eastOffset, heading);
            latRange.Should().BeApproximately(eastOffset, 0.01);

            heading = 180;
            latRange = Functions.LatRange(range, longRange, northOffset, eastOffset, heading);
            latRange.Should().BeApproximately(eastOffset, 0.01);

            heading = 90;
            latRange = Functions.LatRange(range, longRange, northOffset, eastOffset, heading);
            latRange.Should().BeApproximately(northOffset, 0.01);

            heading = 270;
            latRange = Functions.LatRange(range, longRange, northOffset, eastOffset, heading);
            latRange.Should().BeApproximately(northOffset, 0.01);

            heading = 5;
            latRange = Functions.LatRange(range, longRange, northOffset, eastOffset, heading);
            latRange.Should().BeApproximately(20057.458, 0.01);
        }

        [Test]
        public void Chapter2_6_05_ValidateRelLatLongPositionsTest()
        {
            Functions.RelLongRange(117.050, 2.00, 3.00).Should().Be(Functions.RelativeLongLocation.Front);
            Functions.RelLongRange(-117.050, 2.00, 3.00).Should().Be(Functions.RelativeLongLocation.Behind);
            Functions.RelLongRange(1.17050, 2.00, 3.00).Should().Be(Functions.RelativeLongLocation.Side);

            Functions.RelLatRange(117.050, 2.00, 3.00).Should().Be(Functions.RelativeLatLocation.Right);
            Functions.RelLatRange(-117.050, 2.00, 3.00).Should().Be(Functions.RelativeLatLocation.Left);
            Functions.RelLatRange(1.17050, 2.00, 3.00).Should().Be(Functions.RelativeLatLocation.Center);
        }

        [Test]
        public void Chapter2_6_06_ValidateRvPreciseRelativeLocationTest_InPath()
        {
            Functions.RvPreciseRelativeLocation(100, 105, Functions.RelativeLongLocation.Front, Functions.RelativeLatLocation.Center,
                    -1, -1, -1, -1, -1, -1)
                .Should().Be(Functions.PreciseRelativeLocation.FcwEeblInPathTarget);
        }

        [Test]
        public void Chapter2_6_06_ValidateRvPreciseRelativeLocationTest_ImaLeft()
        {
            Functions.RvPreciseRelativeLocation(40, 130, Functions.RelativeLongLocation.Front, Functions.RelativeLatLocation.Default,
                    -1, -1, -1, -1, -1, -1)
                .Should().Be(Functions.PreciseRelativeLocation.ImaLeft);

            Functions.RvPreciseRelativeLocation(90, 180, Functions.RelativeLongLocation.Front, Functions.RelativeLatLocation.Default,
                    -1, -1, -1, -1, -1, -1)
                .Should().Be(Functions.PreciseRelativeLocation.ImaLeft);

            Functions.RvPreciseRelativeLocation(250, 340, Functions.RelativeLongLocation.Front, Functions.RelativeLatLocation.Default,
                    -1, -1, -1, -1, -1, -1)
                .Should().Be(Functions.PreciseRelativeLocation.ImaLeft);

            Functions.RvPreciseRelativeLocation(270, 350, Functions.RelativeLongLocation.Front, Functions.RelativeLatLocation.Default,
                    -1, -1, -1, -1, -1, -1)
                .Should().Be(Functions.PreciseRelativeLocation.ImaLeft);

            Functions.RvPreciseRelativeLocation(290, 10, Functions.RelativeLongLocation.Front, Functions.RelativeLatLocation.Default,
                    -1, -1, -1, -1, -1, -1)
                .Should().Be(Functions.PreciseRelativeLocation.ImaLeft);
        }

        [Test]
        public void Chapter2_6_06_ValidateRvPreciseRelativeLocationTest_ImaRight()
        {
            Functions.RvPreciseRelativeLocation(40, 310, Functions.RelativeLongLocation.Front, Functions.RelativeLatLocation.Default,
                    -1, -1, -1, -1, -1, -1)
                .Should().Be(Functions.PreciseRelativeLocation.ImaRight);

            Functions.RvPreciseRelativeLocation(90, 350, Functions.RelativeLongLocation.Front, Functions.RelativeLatLocation.Default,
                    -1, -1, -1, -1, -1, -1)
                .Should().Be(Functions.PreciseRelativeLocation.ImaRight);

            Functions.RvPreciseRelativeLocation(180, 90, Functions.RelativeLongLocation.Front, Functions.RelativeLatLocation.Default,
                    -1, -1, -1, -1, -1, -1)
                .Should().Be(Functions.PreciseRelativeLocation.ImaRight);

            Functions.RvPreciseRelativeLocation(270, 180, Functions.RelativeLongLocation.Front, Functions.RelativeLatLocation.Default,
                    -1, -1, -1, -1, -1, -1)
                .Should().Be(Functions.PreciseRelativeLocation.ImaRight);

            Functions.RvPreciseRelativeLocation(300, 210, Functions.RelativeLongLocation.Front, Functions.RelativeLatLocation.Default,
                    -1, -1, -1, -1, -1, -1)
                .Should().Be(Functions.PreciseRelativeLocation.ImaRight);
        }

        [Test]
        public void Chapter2_6_06_ValidateRvPreciseRelativeLocationTest_BlindSpot()
        {
            Functions.RvPreciseRelativeLocation(1, 3, Functions.RelativeLongLocation.Behind, Functions.RelativeLatLocation.Default,
                    2, 2, 2, 2, -3.5, 5.5)
                .Should().Be(Functions.PreciseRelativeLocation.VtrftBlindSpotZone);
        }

        [Test]
        public void Chapter2_6_07_ValidateHostVehicleTimeToIntersectionBasedOnLatLongRangesTest()
        {
            Functions.TimeToIntersection(100, 50).Should().Be(2);
        }

        [Test]
        public void Chapter2_6_08_ValidateRemoteVehicleTimeToIntersectionBasedOnLatLongRangesTest()
        {
            Functions.TimeToIntersection(100, 40).Should().Be(2.5);
        }

        [Test]
        public void Chapter2_6_9_ValidateHostVehicleTimeToIntersectionBasedOnDistanceToIntersectionTest()
        {
            Functions.HostVehicleTimeToIntersectionBasedOnDistanceToIntersection(10, 20, 100).Should().BeApproximately(0.2236, 0.01);
        }

        [Test]
        public void Chapter2_6_10_ValidateRemoveVehicleTimeToIntersectionBasedOnDistanceToIntersectionTest()
        {
            Functions.RemoveVehicleTimeToIntersectionBasedOnDistanceToIntersection(100, 10, 200, 20, 100).Should().BeApproximately(2.012, 0.01);
        }

        [Test]
        public void Chapter2_6_11_ValidateDistanceToPointOfInterestInMetersTest()
        {
            Functions.DistanceToPointOfInterestInMeters(42.292488, -83.736084, 42.292126, -83.736412).Should().BeApproximately(48.3923, 0.01);
        }

        [Test]
        public void Chapter2_6_12_ValidateTimeToPointOfInterestTest()
        {
            Functions.TimeToPointOfInterest(100, 2).Should().Be(50);
        }

        [Test]
        public void ValidateDegreeToRadianTest()
        {
            Functions.DegreeToRadian(45).Should().BeApproximately(0.78, 0.01);
            Functions.DegreeToRadian(90).Should().BeApproximately(1.57, 0.01);

            Math.Tan(Functions.DegreeToRadian(45)).Should().BeApproximately(1, 0.01);
        }

        [Test]
        public void ValidateRadianToDegreesTest()
        {
            Functions.RadianToDegrees(1).Should().BeApproximately(57.29, 0.01);
            Functions.RadianToDegrees(2).Should().BeApproximately(114.59, 0.01);
        }
    }
}
