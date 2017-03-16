using System;
using System.IO;
using System.Text;
using System.Data;
using System.Data.Sql;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;

public partial class ExportFunctions
{
  [System.Security.Permissions.PermissionSet(System.Security.Permissions.SecurityAction.Demand, Name = "FullTrust")]
  
  public static void ExportQuery(SqlString filename, SqlString query, SqlInt16 ExpHeaders, SqlInt16 ExpLFOnly, SqlInt16 NoTrim, SqlString Separator, SqlInt16 Decode)
  {
    SqlDataAdapter adapter;
    SqlConnection connection = new SqlConnection(@"context connection=true");
    FileStream fs; 

    connection.Open();
    adapter = new SqlDataAdapter(query.Value, connection);
    DataTable table = new DataTable();
    adapter.Fill(table);
    connection.Close();
    byte bSep = 9;
    if ((!Separator.IsNull) && (Separator.Value != "")) bSep = (byte)Separator.Value[0];
   
    fs = new FileStream(filename.Value, FileMode.Create, FileAccess.Write);
    
    if (ExpHeaders.Value == 1)
    {
       //Encoding unicode = Encoding.Unicode;
       Encoding unicode = Encoding.GetEncoding(1252);
       int iCols = 0;
       foreach(DataColumn col in table.Columns)
       {
         if (iCols++ > 0) fs.WriteByte(bSep);

         byte[] unicodeBytes = unicode.GetBytes(col.ColumnName.ToString());      
         for(int iX = 0; iX < unicodeBytes.Length; iX++) 
         {  
           if(unicodeBytes[iX] > 0) fs.WriteByte(unicodeBytes[iX]);
         }
       }
       if (ExpLFOnly.Value != 1) fs.WriteByte(13);
       fs.WriteByte(10);
    }
    
    
    foreach (DataRow row in table.Rows)
    {
       //Encoding unicode = Encoding.Unicode;
       Encoding unicode = Encoding.GetEncoding(1252);
       
       int  iCols = 0;
       int  iDecode = Decode.Value;
       bool isMySql  = (iDecode & 16) == 16 ;
       if (isMySql) iDecode -= 16 ;
      
       foreach(DataColumn col in table.Columns)
       {
         bool isNull = row[col] == DBNull.Value;                             
         byte[] unicodeBytes;
         if (iCols++ > 0) fs.WriteByte(bSep);

         if(isNull)
         {
            if(isMySql) {
              fs.WriteByte(92); // backslash
              fs.WriteByte(78); // N
            }
         } else  if (col.DataType == System.Type.GetType("System.Boolean") )
         {
            if ( (bool) row[col] ) { fs.WriteByte(49); } else { fs.WriteByte(48); } ;
         } else  if (col.DataType == System.Type.GetType("System.DateTime") )
         {  
            DateTime dt = (DateTime) row[col];
            unicodeBytes = unicode.GetBytes(dt.ToString("yyyy-MM-dd HH:mm:ss"));
            for(int iX = 0; iX < unicodeBytes.Length; iX++) fs.WriteByte(unicodeBytes[iX]);
         } 
         else if (col.DataType == System.Type.GetType("System.Date") ) 
         {  
            DateTime dt = (DateTime) row[col];
            unicodeBytes = unicode.GetBytes(dt.ToString("yyyy-MM-dd"));
            for(int iX = 0; iX < unicodeBytes.Length; iX++) fs.WriteByte(unicodeBytes[iX]);
         } 
         else 
         {
           if (NoTrim.Value == 1) { unicodeBytes = unicode.GetBytes(row[col].ToString()); }
                             else { unicodeBytes = unicode.GetBytes(row[col].ToString().TrimEnd()); }
                    
           if(isMySql) {
              for(int iX = 0; iX < unicodeBytes.Length; iX++) 
              {  
                 if(unicodeBytes[iX] > 0) {
                     if(unicodeBytes[iX] == 13) {fs.WriteByte(92); fs.WriteByte(114); } // \r
                else if(unicodeBytes[iX] == 10) {fs.WriteByte(92); fs.WriteByte(110); } // \n
                else if(unicodeBytes[iX] ==  9) {fs.WriteByte(92); fs.WriteByte(116); } // \t
                else if(unicodeBytes[iX] == 92) {fs.WriteByte(92); fs.WriteByte( 92); } // \\
                else                                               fs.WriteByte(unicodeBytes[iX]);
                }
              }
          } else {
            for(int iX = 0; iX < unicodeBytes.Length; iX++) 
            {  
              if(unicodeBytes[iX] > 0) {
                     if(Decode.Value  > 0 && unicodeBytes[iX] == 13) fs.WriteByte(182) ;
                else if(Decode.Value  > 0 && unicodeBytes[iX] == 10) fs.WriteByte(172) ;
                else if(Decode.Value  > 0 && unicodeBytes[iX] ==  9) fs.WriteByte(187) ;
                else if(Decode.Value  > 1 && unicodeBytes[iX] == 39) fs.WriteByte(145) ;
                else if(Decode.Value  > 1 && unicodeBytes[iX] == 34) fs.WriteByte(147) ;
                else                                                 fs.WriteByte(unicodeBytes[iX]);
              }
            }
          }
        }
      }
      
      if (ExpLFOnly.Value != 1) fs.WriteByte(13);
      fs.WriteByte(10);
    }

    fs.Close();
  }
  
    
}

