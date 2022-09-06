using System.Linq;
using FluentAssertions;
using SqlSdcLibrary.Specs.Classes;
using TechTalk.SpecFlow;
using TechTalk.SpecFlow.Assist;

namespace SqlSdcLibrary.Specs
{
    [Binding]
    public class NorthAndEastOffsetSteps
    {
        private readonly SharedSteps.SharedContext _sharedContext;

        public NorthAndEastOffsetSteps(SharedSteps.SharedContext sharedContext)
        {
            _sharedContext = sharedContext;
        }

        [Then(@"the result for northOffset and EastOffset should be")]
        public void ThenTheResultForNorthOffsetAndEastOffsetShouldBe(Table table)
        {
            var expectedOutputs = table.CreateSet<OffsetOutput>().ToList();

            foreach (var item in expectedOutputs)
            {
                var actualOutput = _sharedContext.OffsetOutputs.SingleOrDefault(x => x.LinkId == item.LinkId);

                actualOutput.Should().NotBeNull();

                actualOutput.NorthOffset.Should().BeApproximately(item.NorthOffset, 0.001);
                actualOutput.EastOffset.Should().BeApproximately(item.EastOffset, 0.001);
            }
        }
    }
}
