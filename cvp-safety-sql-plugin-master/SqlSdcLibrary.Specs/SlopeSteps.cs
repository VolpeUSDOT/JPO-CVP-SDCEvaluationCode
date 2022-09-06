using System.Collections.Generic;
using System.Linq;
using FluentAssertions;
using TechTalk.SpecFlow;
using TechTalk.SpecFlow.Assist;

namespace SqlSdcLibrary.Specs
{
    [Binding]
    public class SlopeSteps
    {
        private List<Input> inputs;

        [Given(@"the following heading")]
        public void GivenAnVehicleWithTheFollowingHeading(Table table)
        {
            inputs = table.CreateSet<Input>().ToList();
        }

        [When(@"calculating the HVSlope")]
        public void WhenCalculatingTheHVSlope()
        {
            foreach (var input in inputs)
            {
                input.Slope = Functions.HVSlope(input.Heading);
            }
        }

        [Then(@"the HVSlope result should be")]
        public void ThenTheHVSlopeResultShouldBe(Table table)
        {
            var expectedOutput = table.CreateSet<Output>();

            foreach (var item in expectedOutput)
            {
                var actualOutput = inputs.SingleOrDefault(x => x.Id == item.Id);

                actualOutput.Should().NotBeNull();

                actualOutput.Slope.Should().BeApproximately(item.Slope, 0.01);
            }
        }

        private class Input
        {
            public int Id { get; set; }
            public double Heading { get; set; }
            public double Slope { get; set; }
        }

        private class Output
        {
            public int Id { get; set; }
            public double Slope { get; set; }
        }
    }
}
