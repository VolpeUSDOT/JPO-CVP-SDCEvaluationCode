using System.Collections.Generic;
using System.Data.SqlTypes;
using System.Linq;
using FluentAssertions;
using Microsoft.SqlServer.Types;
using SqlSdcLibrary.Specs.Classes;
using TechTalk.SpecFlow;
using TechTalk.SpecFlow.Assist;

namespace SqlSdcLibrary.Specs
{
    [Binding]
    public class SharedSteps
    {
        private readonly SharedContext _sharedContext;

        public SharedSteps(SharedContext sharedContext)
        {
            _sharedContext = sharedContext;
        }

        [Given(@"vehicles")]
        public void GivenVehicles(Table table)
        {
            _sharedContext.VehicleInputs = table.CreateSet<VehicleInput>().ToList();
        }

        [Given(@"the following vehicles are associated with one-another")]
        public void GivenTheFollowingVehiclesAreAssociatedWithOne_Another(Table table)
        {
            _sharedContext.LinkedVehicles = table.CreateSet<LinkInput>().ToList();

            foreach (var item in _sharedContext.LinkedVehicles)
            {
                _sharedContext.VehicleInputs.Any(x => x.VehicleId == item.HostVehicleId).Should().BeTrue();
                _sharedContext.VehicleInputs.Any(x => x.VehicleId == item.RemoteVehicleId).Should().BeTrue();
            }
        }

        [When(@"calculating Northing and Easting")]
        public void WhenCalculatingNorthingAndEasting()
        {
            foreach (var item in _sharedContext.VehicleInputs)
            {
                var point1 = SqlGeography.Point(item.Latitude, item.Longitude, item.Projection);
                SqlFunctions.GetUtm(point1, out SqlDouble northing, out SqlDouble easting, out SqlString zona);

                var actualOutput = new NorthingEastingOutput()
                {
                    VehicleId = item.VehicleId,
                    Northing = northing.Value,
                    Easting = easting.Value,
                    Zona = zona.Value,
                };

                _sharedContext.NorthEastingOutputs.Add(actualOutput);
            }
        }

        [When(@"calculating NorthOffset and EastOffset")]
        public void WhenCalculatingNorthOffsetAndEastOffset()
        {
            WhenCalculatingNorthingAndEasting();

            foreach (var item in _sharedContext.LinkedVehicles)
            {
                var hostVehicle =
                    _sharedContext.NorthEastingOutputs.SingleOrDefault(x => x.VehicleId == item.HostVehicleId);
                var remoteVehicle =
                    _sharedContext.NorthEastingOutputs.SingleOrDefault(x => x.VehicleId == item.RemoteVehicleId);

                hostVehicle.Should().NotBeNull();
                remoteVehicle.Should().NotBeNull();

                var output = new OffsetOutput()
                {
                    LinkId = item.LinkId,
                    NorthOffset = Functions.Offset(remoteVehicle.Northing, hostVehicle.Northing),
                    EastOffset = Functions.Offset(remoteVehicle.Easting, hostVehicle.Easting),
                };

                _sharedContext.OffsetOutputs.Add(output);
            }
        }

        [When(@"calculating Range")]
        public void WhenCalculatingRange()
        {
            WhenCalculatingNorthOffsetAndEastOffset();

            foreach (var item in _sharedContext.OffsetOutputs)
            {
                _sharedContext.RangeOutputs.Add(new RangeOutput()
                {
                    LinkId = item.LinkId,
                    Range = Functions.Range(item.NorthOffset, item.EastOffset),
                });
            }
        }

        [Given(@"Heading of")]
        public void GivenHeadingOf(Table table)
        {
            _sharedContext.HeadingInputs = table.CreateSet<HeadingInput>().ToList();
        }

        [When(@"calculating the Longitudinal Range")]
        public void WhenCalculatingTheLongitudinalRange()
        {
            WhenCalculatingRange();

            foreach (var item in _sharedContext.LinkedVehicles)
            {
                var heading = _sharedContext.HeadingInputs.SingleOrDefault(x => x.VehicleId == item.HostVehicleId);
                var offset = _sharedContext.OffsetOutputs.SingleOrDefault(x => x.LinkId == item.LinkId);

                heading.Should().NotBeNull();
                offset.Should().NotBeNull();

                var output = new LongRangeOutput()
                {
                    LinkId = item.LinkId
                };

                output.LongRange = Functions.LongRange(offset.NorthOffset, offset.EastOffset, heading.Heading);

                _sharedContext.LongRangeOutputs.Add(output);
            }
        }

        [When(@"calculating the Latitudinal Range")]
        public void WhenCalculatingTheLatitudinalRange()
        {
            WhenCalculatingTheLongitudinalRange();

            foreach (var item in _sharedContext.LinkedVehicles)
            {
                var range = _sharedContext.RangeOutputs.SingleOrDefault(x => x.LinkId == item.LinkId);
                var heading = _sharedContext.HeadingInputs.SingleOrDefault(x => x.VehicleId == item.HostVehicleId);
                var offset = _sharedContext.OffsetOutputs.SingleOrDefault(x => x.LinkId == item.LinkId);
                var longRange = _sharedContext.LongRangeOutputs.SingleOrDefault(x => x.LinkId == item.LinkId);

                range.Should().NotBeNull();
                heading.Should().NotBeNull();
                offset.Should().NotBeNull();
                longRange.Should().NotBeNull();

                _sharedContext.LatRangeOutputs.Add(new LatRangeOutput()
                {
                    LinkId = item.LinkId,
                    LatRange = Functions.LatRange(range.Range, longRange.LongRange, offset.NorthOffset,
                        offset.EastOffset, heading.Heading),
                });
            }
        }

        [Given(@"car length and width")]
        public void GivenCarLengthAndWidth(Table table)
        {
            _sharedContext.CarSizeInputs = table.CreateSet<CarSizeInput>().ToList();
        }

        [When(@"calculating the Relative Latitudinal and Longitudinal Positions")]
        public void WhenCalculatingTheRelativeLatitudinalAndLongitudinalPositions()
        {
            WhenCalculatingTheLatitudinalRange();

            foreach (var item in _sharedContext.LinkedVehicles)
            {
                var hostCarsizeInput =
                    _sharedContext.CarSizeInputs.SingleOrDefault(x => x.VehicleId == item.HostVehicleId);
                var remoteCarsizeInput =
                    _sharedContext.CarSizeInputs.SingleOrDefault(x => x.VehicleId == item.RemoteVehicleId);
                var heading = _sharedContext.HeadingInputs.SingleOrDefault(x => x.VehicleId == item.HostVehicleId);
                var longrange = _sharedContext.LongRangeOutputs.SingleOrDefault(x => x.LinkId == item.LinkId);
                var latrange = _sharedContext.LatRangeOutputs.SingleOrDefault(x => x.LinkId == item.LinkId);

                hostCarsizeInput.Should().NotBeNull();
                remoteCarsizeInput.Should().NotBeNull();
                heading.Should().NotBeNull();
                longrange.Should().NotBeNull();
                latrange.Should().NotBeNull();

                var relLatLongLocationOutput = new RelLatLongLocationOutput
                {
                    LinkId = item.LinkId,
                    RelativeLongLocation = Functions.RelLongRange(longrange.LongRange, hostCarsizeInput.Length,
                        remoteCarsizeInput.Length),
                    RelativeLatLocation = Functions.RelLatRange(latrange.LatRange, hostCarsizeInput.Width,
                        remoteCarsizeInput.Width),
                };

                _sharedContext.RelLatLongLocationOutputs.Add(relLatLongLocationOutput);
            }
        }

        [When(@"calculating the Precise Relative Location")]
        public void WhenCalculatingThePreciseRelativeLocation()
        {
            WhenCalculatingTheRelativeLatitudinalAndLongitudinalPositions();

            foreach (var item in _sharedContext.LinkedVehicles)
            {
                var hostVehicleHeading =
                    _sharedContext.HeadingInputs.SingleOrDefault(x => x.VehicleId == item.HostVehicleId);
                var remoteVehicleHeading =
                    _sharedContext.HeadingInputs.SingleOrDefault(x => x.VehicleId == item.RemoteVehicleId);
                var relativePos =
                    _sharedContext.RelLatLongLocationOutputs.SingleOrDefault(x => x.LinkId == item.LinkId);
                var hostVehicleSize =
                    _sharedContext.CarSizeInputs.SingleOrDefault(x => x.VehicleId == item.HostVehicleId);
                var remoteVehicleSize =
                    _sharedContext.CarSizeInputs.SingleOrDefault(x => x.VehicleId == item.RemoteVehicleId);
                var longrange = _sharedContext.LongRangeOutputs.SingleOrDefault(x => x.LinkId == item.LinkId);
                var latrange = _sharedContext.LatRangeOutputs.SingleOrDefault(x => x.LinkId == item.LinkId);

                hostVehicleHeading.Should().NotBeNull();
                remoteVehicleHeading.Should().NotBeNull();
                relativePos.Should().NotBeNull();
                hostVehicleSize.Should().NotBeNull();
                remoteVehicleSize.Should().NotBeNull();
                longrange.Should().NotBeNull();
                latrange.Should().NotBeNull();

                var output = new PreciseRelLocationOutput()
                {
                    LinkId = item.LinkId,
                };

                output.PreciseRelativeLocation = Functions.RvPreciseRelativeLocation(
                    hostVehicleHeading.Heading,
                    remoteVehicleHeading.Heading,
                    relativePos.RelativeLongLocation,
                    relativePos.RelativeLatLocation,
                    hostVehicleSize.Length,
                    hostVehicleSize.Width,
                    remoteVehicleSize.Length,
                    remoteVehicleSize.Width,
                    longrange.LongRange,
                    latrange.LatRange
                );

                _sharedContext.PreciseRelLocationOutputs.Add(output);
            }
        }

        [AfterScenario()]
        public void EmptySharedContext()
        {
            _sharedContext.Clear();
        }

        public class SharedContext
        {
            public SharedContext()
            {
                VehicleInputs = new List<VehicleInput>();
                LinkedVehicles = new List<LinkInput>();
                NorthEastingOutputs = new List<NorthingEastingOutput>();
                OffsetOutputs = new List<OffsetOutput>();
                RangeOutputs = new List<RangeOutput>();
                HeadingInputs = new List<HeadingInput>();
                LongRangeOutputs = new List<LongRangeOutput>();
                LatRangeOutputs = new List<LatRangeOutput>();
                CarSizeInputs = new List<CarSizeInput>();
                RelLatLongLocationOutputs = new List<RelLatLongLocationOutput>();
                PreciseRelLocationOutputs = new List<PreciseRelLocationOutput>();
            }

            public List<VehicleInput> VehicleInputs { get; set; }
            public List<LinkInput> LinkedVehicles { get; set; }
            public List<NorthingEastingOutput> NorthEastingOutputs { get; set; }
            public List<OffsetOutput> OffsetOutputs { get; set; }
            public List<RangeOutput> RangeOutputs { get; set; }
            public List<HeadingInput> HeadingInputs { get; set; }
            public List<LongRangeOutput> LongRangeOutputs { get; set; }
            public List<LatRangeOutput> LatRangeOutputs { get; set; }
            public List<CarSizeInput> CarSizeInputs { get; set; }
            public List<RelLatLongLocationOutput> RelLatLongLocationOutputs { get; set; }
            public List<PreciseRelLocationOutput> PreciseRelLocationOutputs { get; set; }

            public void Clear()
            {
                VehicleInputs.Clear();
                LinkedVehicles.Clear();
                NorthEastingOutputs.Clear();
                OffsetOutputs.Clear();
                RangeOutputs.Clear();
                HeadingInputs.Clear();
                LongRangeOutputs.Clear();
                LatRangeOutputs.Clear();
                CarSizeInputs.Clear();
                RelLatLongLocationOutputs.Clear();
                PreciseRelLocationOutputs.Clear();
            }
        }
    }
}