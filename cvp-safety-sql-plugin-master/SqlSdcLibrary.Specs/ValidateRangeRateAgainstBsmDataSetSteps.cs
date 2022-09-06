using System;
using System.Collections.Generic;
using System.Data.SqlTypes;
using System.Linq;
using FluentAssertions;
using Microsoft.SqlServer.Types;
using Newtonsoft.Json;
using SqlSdcLibrary.Specs.Classes;
using TechTalk.SpecFlow;
using TechTalk.SpecFlow.Assist;

namespace SqlSdcLibrary.Specs
{
    [Binding]
    public class ValidateRangeRateAgainstBsmDataSetSteps
    {
        private List<BsmSampleDataSetInput> _bsmSampleDataSet;
        private readonly List<BsmSampleDataSetOutput> _bsmSampleDataSetOutput = new List<BsmSampleDataSetOutput>();

        [Given(@"the following BSM sample data set")]
        public void GivenTheFolllowingBSMSampleDataSet(Table table)
        {
            _bsmSampleDataSet = table.CreateSet<BsmSampleDataSetInput>().ToList();
        }

        [When(@"I calculate the Range and RangeRate")]
        public void WhenICalculateTheRangeAndRangeRate()
        {
            foreach (var item in _bsmSampleDataSet)
            {
                var hvPoint = SqlGeography.Point(item.HV_Latitude, item.HV_Longitude, 4326);
                var rvPoint = SqlGeography.Point(item.RV_Latitude, item.RV_Longitude, 4326);
                SqlFunctions.GetUtm(hvPoint, out SqlDouble hvNorthing, out SqlDouble hvEasting, out SqlString hvZona);
                SqlFunctions.GetUtm(rvPoint, out SqlDouble rvNorthing, out SqlDouble rvEasting, out SqlString rvZona);

                var northOffset = Functions.Offset(rvNorthing.Value, hvNorthing.Value);
                var eastOffset = Functions.Offset(rvEasting.Value, hvEasting.Value);

                var range = Functions.Range(northOffset, eastOffset);

                _bsmSampleDataSetOutput.Add(new BsmSampleDataSetOutput()
                {
                    Time = item.HV_Time,
                    HV_Northing = hvNorthing.Value,
                    HV_Easting = hvEasting.Value,
                    RV_Northing = rvNorthing.Value,
                    RV_Easting = rvEasting.Value,
                    NorthOffset = northOffset,
                    EastOffset = eastOffset,
                    Range = range,
                    RangeRate = double.NaN,
                });
            }

            foreach (var item in _bsmSampleDataSetOutput)
            {
                var ranges = _bsmSampleDataSetOutput.Where(x => x.Time <= item.Time).Reverse().Take(4).Reverse().ToList();
                if (ranges.Count > 3)
                {
                    var scaledRange = Functions.ScaledDRange(
                        ranges[0].Range, 
                        ranges[1].Range, 
                        ranges[2].Range,
                        ranges[3].Range);

                    var dt = 0.1;

                    var rangeRate = Functions.RangeRate(scaledRange, dt);

                    item.RangeRate = rangeRate;
                } else
                {
                    item.RangeRate = double.NaN;
                }
            }
        }

        [Then(@"the results within the data set should match with the calculated results")]
        public void ThenTheResultsWithinTheDataSetShouldMatchWithTheCalculatedResults()
        {
            // validate Range
            foreach (var item in _bsmSampleDataSet)
            {
                var output = _bsmSampleDataSetOutput.Single(x => x.Time == item.HV_Time);

                Math.Round(output.Range, 2).Should().BeApproximately(item.Range, 0.01, JsonConvert.SerializeObject(output, Formatting.Indented));
            }

            // validate RangeRate
            foreach (var item in _bsmSampleDataSet)
            {
                if (double.IsNaN(item.RangeRate))
                {
                    continue;
                }

                var output = _bsmSampleDataSetOutput.Single(x => x.Time == item.HV_Time);

                Math.Round(output.RangeRate, 2).Should().BeApproximately(item.RangeRate, 0.01, JsonConvert.SerializeObject(output, Formatting.Indented));
            }
        }
    }
}
