using System.Linq;
using FluentAssertions;
using SqlSdcLibrary.Specs.Classes;
using TechTalk.SpecFlow;
using TechTalk.SpecFlow.Assist;

namespace SqlSdcLibrary.Specs
{
    [Binding]
    public class LongRangeSteps
    {
        private readonly SharedSteps.SharedContext _sharedContext;

        public LongRangeSteps(SharedSteps.SharedContext sharedContext)
        {
            _sharedContext = sharedContext;
        }

        [Then(@"the Longitudinal Range results should be")]
        public void ThenTheLongitudinalRangeResultsShouldBe(Table table)
        {
            var expectedOutput = table.CreateSet<LongRangeOutput>();

            foreach (var item in expectedOutput)
            {
                var actualOutput = _sharedContext.LongRangeOutputs.SingleOrDefault(x => x.LinkId == item.LinkId);

                actualOutput.Should().NotBeNull();

                actualOutput.LongRange.Should().BeApproximately(item.LongRange, 0.001);
            }
        }
    }
}