using System.Linq;
using FluentAssertions;
using SqlSdcLibrary.Specs.Classes;
using TechTalk.SpecFlow;
using TechTalk.SpecFlow.Assist;

namespace SqlSdcLibrary.Specs
{
    [Binding]
    public class PreciseRelativeLocationSteps
    {
        private readonly SharedSteps.SharedContext _sharedContext;

        public PreciseRelativeLocationSteps(SharedSteps.SharedContext sharedContext)
        {
            _sharedContext = sharedContext;
        }

        [Then(@"the Precise Relative Location results should be")]
        public void ThenThePreciseRelativeLocationResultsShouldBe(Table table)
        {
            var expectedOutput = table.CreateSet<PreciseRelLocationOutput>();

            foreach (var item in expectedOutput)
            {
                var actualOutput = _sharedContext.PreciseRelLocationOutputs.SingleOrDefault(x => x.LinkId == item.LinkId);

                actualOutput.Should().NotBeNull();

                actualOutput.PreciseRelativeLocation.Should().Be(item.PreciseRelativeLocation);
            }
        }
    }
}
