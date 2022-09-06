using System.Linq;
using FluentAssertions;
using SqlSdcLibrary.Specs.Classes;
using TechTalk.SpecFlow;
using TechTalk.SpecFlow.Assist;

namespace SqlSdcLibrary.Specs
{

    [Binding]
    public class NorthingEastingSteps
    {
        private readonly SharedSteps.SharedContext _sharedContext;

        public NorthingEastingSteps(SharedSteps.SharedContext sharedContext)
        {
            _sharedContext = sharedContext;
        }

        [Then(@"the result should be")]
        public void ThenTheResultShouldBe(Table table)
        {
            var expectedOutput = table.CreateSet<NorthingEastingOutput>();

            foreach (var item in expectedOutput)
            {
                var actualOutput = _sharedContext.NorthEastingOutputs.SingleOrDefault(x => x.VehicleId == item.VehicleId);

                actualOutput.Should().NotBeNull();

                actualOutput.Northing.Should().BeApproximately(item.Northing, 0.01);
                actualOutput.Easting.Should().BeApproximately(item.Easting, 0.01);
                actualOutput.Zona.Should().Be(item.Zona);
            }
        }
    }
}
