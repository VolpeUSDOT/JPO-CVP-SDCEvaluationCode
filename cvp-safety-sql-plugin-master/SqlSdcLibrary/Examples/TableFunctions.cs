using System;
using System.Collections;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;
using Microsoft.SqlServer.Types;

namespace SqlSdcLibrary.Examples
{
    public class TableFunctions
    {
        /* table result */
        [SqlFunction(FillRowMethodName = "GetDistance")]
        public static IEnumerable Distance(SqlGeography point1, SqlGeography point2)
        {
            return null;
        }

        public static void GetDistance(Object obj, out SqlString name, SqlDouble distance)
        {
            name = "example";
            distance = 1;
        }

        /* single result */
        [SqlFunction(DataAccess = DataAccessKind.Read)]
        public static double ReturnDistance()
        {
            using (SqlConnection conn = new SqlConnection("context connection=true"))
            {
                conn.Open();
                var cmd = new SqlCommand("SELECT COUNT(*) AS 'Order Count' FROM SalesOrderHeader", conn);
                return (int)cmd.ExecuteScalar();
            }
        }

        /* aggregate result */

    }
}
