using System.Collections.Generic;
using System.Linq;
using FluentAssertions;
using TechTalk.SpecFlow;
using TechTalk.SpecFlow.Assist;

namespace SqlSdcLibrary.Specs
{
    [Binding]
    public class RangeRateSteps
    {
        private IEnumerable<Input> inputs;
        private List<Output> outputs = new List<Output>();

        [Given(@"an ScaledDRange time serie")]
        public void GivenAnScaledDRangeTimeSerie(Table table)
        {
            inputs = table.CreateSet<Input>();
        }

        [Given(@"a dT time difference between data points")]
        public void GivenADTTimeDifferenceBetweenDataPoints(Table table)
        {
            outputs = table.CreateSet<Output>().ToList();

            foreach (var item in outputs)
            {
                var input = inputs.SingleOrDefault(x => x.ScaledDRangeId == item.ScaledDRangeId);

                input.Should().NotBeNull();

                item.Input = input;
            }
        }

        [When(@"calculating Range Rate")]
        public void WhenCalculatingRangeRate()
        {
            foreach (var output in outputs)
            {
                var scaledDRange = Functions.ScaledDRange(output.Input.Range1, output.Input.Range2, output.Input.Range3, output.Input.Range4);
                output.RangeRate = Functions.RangeRate(scaledDRange, output.dT);
            }
        }
        
        [Then(@"the range rate result should be")]
        public void ThenTheRangeRateResultShouldBe(Table table)
        {
            var expectedOutput = table.CreateSet<Output>();

            foreach (var item in expectedOutput)
            {
                var actualOutput = outputs.SingleOrDefault(x => x.ScaledDRangeId == item.ScaledDRangeId);

                actualOutput.Should().NotBeNull();

                actualOutput.RangeRate.Should().BeApproximately(item.RangeRate, 0.01);
            }
        }

        private class Input
        {
            public int ScaledDRangeId { get; set; }
            public double Range1 { get; set; }
            public double Range2 { get; set; }
            public double Range3 { get; set; }
            public double Range4 { get; set; }
        }

        private class Output
        {
            public int ScaledDRangeId { get; set; }
            public Input Input { get; set; }
            public double dT { get; set; }
            public double RangeRate { get; set; }
        }
    }
}
