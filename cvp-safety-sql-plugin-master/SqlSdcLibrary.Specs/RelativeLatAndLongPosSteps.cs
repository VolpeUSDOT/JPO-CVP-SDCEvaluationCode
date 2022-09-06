using System.Linq;
using FluentAssertions;
using SqlSdcLibrary.Specs.Classes;
using TechTalk.SpecFlow;
using TechTalk.SpecFlow.Assist;

namespace SqlSdcLibrary.Specs
{
    [Binding]
    public class RelativeLatAndLongPosSteps
    {
        private readonly SharedSteps.SharedContext _sharedContext;

        public RelativeLatAndLongPosSteps(SharedSteps.SharedContext sharedContext)
        {
            _sharedContext = sharedContext;
        }

        [Then(@"the Relative Latitudinal and Longitudinal Positions results should be")]
        public void ThenTheRelativeLatitudinalAndLongitudinalPositionsResultsShouldBe(Table table)
        {
            var expectedOutput = table.CreateSet<RelLatLongLocationOutput>();

            foreach (var item in expectedOutput)
            {
                var actualOutput = _sharedContext.RelLatLongLocationOutputs.SingleOrDefault(x => x.LinkId == item.LinkId);

                actualOutput.Should().NotBeNull();

                actualOutput.RelativeLongLocation.Should().Be(item.RelativeLongLocation);
                actualOutput.RelativeLatLocation.Should().Be(item.RelativeLatLocation);
            }
        }
    }
}
