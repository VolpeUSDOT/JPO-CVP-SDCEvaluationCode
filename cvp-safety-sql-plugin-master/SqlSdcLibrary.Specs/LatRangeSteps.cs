using System.Linq;
using FluentAssertions;
using SqlSdcLibrary.Specs.Classes;
using TechTalk.SpecFlow;
using TechTalk.SpecFlow.Assist;

namespace SqlSdcLibrary.Specs
{
    [Binding]
    public class LatRangeSteps
    {
        private readonly SharedSteps.SharedContext _sharedContext;

        public LatRangeSteps(SharedSteps.SharedContext sharedContext)
        {
            _sharedContext = sharedContext;
        }

        [Then(@"the Latitudinal Range should be")]
        public void ThenTheLatitudinalRangeShouldBe(Table table)
        {
            var expectedOutput = table.CreateSet<LatRangeOutput>();

            foreach (var item in expectedOutput)
            {
                var actualOutput = _sharedContext.LatRangeOutputs.SingleOrDefault(x => x.LinkId == item.LinkId);

                actualOutput.Should().NotBeNull();

                actualOutput.LatRange.Should().BeApproximately(item.LatRange, 0.01);
            }
        }
    }
}
