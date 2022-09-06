namespace SqlSdcLibrary.Specs.Classes
{
    public class RelLatLongLocationOutput
    {
        public int LinkId { get; set; }
        public Functions.RelativeLongLocation RelativeLongLocation { get; set; }
        public Functions.RelativeLatLocation RelativeLatLocation { get; set; }
    }
}
