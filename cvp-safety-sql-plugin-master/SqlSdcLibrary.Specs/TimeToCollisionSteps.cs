using System.Collections.Generic;
using System.Linq;
using FluentAssertions;
using TechTalk.SpecFlow;
using TechTalk.SpecFlow.Assist;

namespace SqlSdcLibrary.Specs
{
    [Binding]
    public class TimeToCollisionSteps
    {
        private IEnumerable<Input> inputs;
        private List<Output> outputs = new List<Output>();

        [Given(@"a Range and RangeRate")]
        public void GivenARangeAndRangeRate(Table table)
        {
            inputs = table.CreateSet<Input>();
        }

        [When(@"calculating Time-to-Collision")]
        public void WhenCalculatingTime_To_Collision()
        {
            foreach (var item in inputs)
            {
                item.TimeToCollision = Functions.TimeToCollision(item.Range, item.RangeRate);
            }
        }

        [Then(@"the Time-to-collision result should be")]
        public void ThenTheTime_To_CollisionResultShouldBe(Table table)
        {
            var expectedOutput = table.CreateSet<Output>();

            foreach (var item in expectedOutput)
            {
                var actualOutput = inputs.SingleOrDefault(x => x.Id == item.Id);

                actualOutput.Should().NotBeNull();

                actualOutput.TimeToCollision.Should().BeApproximately(item.TimeToCollision, 0.01);
            }
        }

        private class Input
        {
            public int Id { get; set; }
            public double Range { get; set; }
            public double RangeRate { get; set; }
            public double TimeToCollision { get; set; }
        }

        private class Output
        {
            public int Id { get; set; }
            public double TimeToCollision { get; set; }
        }
    }
}
