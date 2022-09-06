using System.Collections.Generic;
using System.Linq;
using FluentAssertions;
using TechTalk.SpecFlow;
using TechTalk.SpecFlow.Assist;

namespace SqlSdcLibrary.Specs
{
    [Binding]
    public class DistanceToPointOfInterestSteps
    {
        private List<PointInput> points;
        private double result;

        [Given(@"two points")]
        public void GivenTwoPoints(Table table)
        {
            points = table.CreateSet<PointInput>().ToList();
        }
        
        [When(@"calculating the Distance to Point of Interest")]
        public void WhenCalculatingTheDistanceToPointOfInterest()
        {
            var point1 = points[0];
            var point2 = points[1];

            result = Functions.DistanceToPointOfInterestInMeters(point1.Latitude, point1.Longitude, point2.Latitude,
                point2.Longitude);
        }
        
        [Then(@"the Distance to Point of Interest should be (.*)")]
        public void ThenTheDistanceToPointOfInterestShouldBe(double value)
        {
            result.Should().BeApproximately(value, 0.01);
        }

        public class PointInput
        {
            public int PointId { get; set; }
            public double Latitude { get; set; }
            public double Longitude { get; set; }
            public int Projection { get; set; }
        }
    }
}
