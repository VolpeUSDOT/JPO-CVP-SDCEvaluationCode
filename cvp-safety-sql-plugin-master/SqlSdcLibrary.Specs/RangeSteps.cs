using System.Collections.Generic;
using System.Linq;
using FluentAssertions;
using Microsoft.SqlServer.Types;
using SqlSdcLibrary.Specs.Classes;
using TechTalk.SpecFlow;
using TechTalk.SpecFlow.Assist;

namespace SqlSdcLibrary.Specs
{
    [Binding]
    public class RangeSteps
    {
        private readonly SharedSteps.SharedContext _sharedContext;
        private List<PositionInput> hostVehicle;
        private List<PositionInput> remoteVehicle;
        private double rangeRate;
        private double dt;

        public RangeSteps(SharedSteps.SharedContext sharedContext)
        {
            _sharedContext = sharedContext;
        }
        
        [Then(@"the range should be")]
        public void ThenTheRangeShouldBe(Table table)
        {
            var expectedOutput = table.CreateSet<RangeOutput>();

            foreach (var item in expectedOutput)
            {
                var actualOutput = _sharedContext.RangeOutputs.SingleOrDefault(x => x.LinkId == item.LinkId);

                actualOutput.Should().NotBeNull();

                actualOutput.Range.Should().BeApproximately(item.Range, 0.01);
            }
        }

        [Given(@"Host vehicle with locations over time")]
        public void GivenHostVehicleWithLocationsOverTime(Table table)
        {
            hostVehicle = table.CreateSet<PositionInput>().ToList();
        }

        [Given(@"Remote vehicle with locations over time")]
        public void GivenRemoteVehicleWithLocationsOverTime(Table table)
        {
            remoteVehicle = table.CreateSet<PositionInput>().ToList();
        }

        [Given(@"dt is (.*)")]
        public void GivenDtIs(double dtValue)
        {
            dt = dtValue;
        }

        [When(@"calculating Range Rate for vehicles")]
        public void WhenCalculatingRangeRateForVehicles()
        {
            hostVehicle.Count.Should().Be(remoteVehicle.Count);

            var ranges = new List<double>();

            foreach (var host in hostVehicle.Take(4))
            {
                var remote = remoteVehicle.Single(x => x.PositionId == host.PositionId);

                var hostPoint = SqlGeography.Point(host.Latitude, host.Longitude, host.Projection);
                var remotePoint = SqlGeography.Point(remote.Latitude, remote.Longitude, remote.Projection);

                var range = SqlFunctions.Range(remotePoint, hostPoint).Value;
                ranges.Add(range);
            }

            double scaledRange = Functions.ScaledDRange(ranges[0], ranges[1], ranges[2], ranges[3]);
            rangeRate = Functions.RangeRate(scaledRange, dt);
        }

        [Then(@"the Range Rate should be (.*)")]
        public void ThenTheRangeRangeShouldBe(double value)
        {
            value.Should().BeApproximately(rangeRate, 0.01);
        }

        public class PositionInput
        {
            public int PositionId { get; set; }
            public double Latitude { get; set; }
            public double Longitude { get; set; }
            public int Projection { get; set; }
        }
    }
}
