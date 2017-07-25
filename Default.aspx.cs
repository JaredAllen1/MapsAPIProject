using System;
using System.Windows;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using Newtonsoft.Json;
using System.IO;
using WebApplication2.DAL;
using System.Data.Entity.Spatial;
using Microsoft.SqlServer;
using System.Data.SqlClient;
using System.Data;
using Microsoft.SqlServer.Types;

namespace WebApplication2
{
   public partial class _Default : Page
   {
      protected void Page_Load(object sender, EventArgs e)
      {
         if(!Page.IsPostBack)
         {
            using (HomePlansContext db = new HomePlansContext())
            {          
                  List<Neighborhood> tmpNhList = db.Neighborhoods.ToList();

                  foreach (Neighborhood tmpNh in tmpNhList)
                  {
                     ListItem tmpLI = new ListItem(tmpNh.Name, tmpNh.NeighborhoodID.ToString());
                     lstNeighborhoods.Items.Add(tmpLI);
                  }           
            }
         }

      }

      protected void btnSave_Click(object sender, EventArgs e)
      {
         string tmpCoords = txtCoords.Text;
         tmpCoords = tmpCoords.TrimEnd('|');
         string[] tmpPolyArr = tmpCoords.Split('|',',');

         using (HomePlansContext db = new HomePlansContext())
         {
            string currNh = lstNeighborhoods.SelectedItem.Value;
            int tmpNhID = Convert.ToInt32(currNh);
            bool tmpIsNew = false;
            NeighborhoodGPS tmpNh = db.NeighborhoodGPSSet.SingleOrDefault(x => x.NeighborhoodID == tmpNhID);

            //only make new entry if the ID doesn't exist in the table
            if (tmpNh == null)
            {
               tmpIsNew = true;
               tmpNh = new NeighborhoodGPS();
               tmpNh.NeighborhoodID = tmpNhID;
            }

            tmpNh.CoordinateString = tmpCoords;
            
            string tmpPolyString = TxtCoords_to_PolyString();//converts to SqlGeography type to reorient object so you can draw the polygon either way

            tmpNh.CoordinateGPS = DbGeography.FromText(tmpPolyString);

            if (tmpIsNew)
               db.NeighborhoodGPSSet.Add(tmpNh);

            db.SaveChanges();
         }
      }

      protected void btnGetCoords_Click(object sender, EventArgs e)
      {
         using (HomePlansContext db = new HomePlansContext())
         {
            int id = Convert.ToInt32(lstNeighborhoods.SelectedItem.Value);
            NeighborhoodGPS coords = db.NeighborhoodGPSSet.First(c => c.NeighborhoodID == id);
            txtCoords.Text = coords.CoordinateString;
         }
      }
      private string MakePolygonValid(string polygonWkt)
      {    
         //make sqlgeography instance from WKT string
         SqlGeography sqlPolygon = SqlGeography.STGeomFromText(new System.Data.SqlTypes.SqlChars(polygonWkt), 4326).MakeValid();
         if (sqlPolygon.STArea() > 255000000000000L) //if area of polygon is larger than half the earth, 
         {
            sqlPolygon = sqlPolygon.ReorientObject();//flip the polygon so inside becomes the outside
         }
         DbGeography polygon = DbGeography.FromBinary(sqlPolygon.STAsBinary().Value); //convert SqlGeography to DbGeography 
         polygonWkt = polygon.AsText(); //convert DbGeography to WKT string
         return polygonWkt;
      }

      private string Arr_to_PolyString(string[] tmpPolyArr)
      {
         string tmpPolyString = "MULTIPOLYGON((("; //initialize WKT string for a polygon, i.e. in the format "POLYGON((1 1, 2 3, 1 3, 1 2,...))"
         var curr = 1;
         var polyAmt = 1;
         for (int i = 0; i < tmpPolyArr.Length; i += 2)
         {
            if(i != 0 && i != curr){            
               if (tmpPolyArr[i] == tmpPolyArr[0]||tmpPolyArr[i] == tmpPolyArr[curr])
               {
                  if(curr == 1)
                     tmpPolyString += tmpPolyArr[1]+ " " + tmpPolyArr[0] + "))";
                  else
                  {
                     tmpPolyString += tmpPolyArr[curr + 1] + " " + tmpPolyArr[curr] + "))";
                  }
                     if (i + 2 < tmpPolyArr.Length)
                     {
                        polyAmt += 1;
                        tmpPolyString += ",((";
                        curr = i+2;
                     }    
                  
               }
               else
                   tmpPolyString += tmpPolyArr[i + 1] + " " + tmpPolyArr[i] + ',';
            }
            else
               tmpPolyString += tmpPolyArr[i + 1] + " " + tmpPolyArr[i] + ','; //flip the values since Well Known Text(WKT) goes by (Long, Lat)        
         }
              tmpPolyString = tmpPolyString.TrimEnd(',');
      
         
         tmpPolyString += ")";//add first coordinate to the end to complete the polygon
         return tmpPolyString;
      }

      protected void btnSearch_Click(object sender, EventArgs e)
      {
         string tmpCoords = txtCoords.Text.TrimEnd('|');
         string[] tmpPolyArr = tmpCoords.Split('|',',');//splits the coordinate string into an array
         string tmpPolyStr = Arr_to_PolyString(tmpPolyArr);//converts array to WKT string
         tmpPolyStr = MakePolygonValid(tmpPolyStr);//converts WKT string to a valid WKT string, if needed
         DbGeography tmpPoly = DbGeography.FromText(tmpPolyStr);//make geography object from valid WKT string

         using (HomePlansContext db = new HomePlansContext())
         {
            
            var tmpRes = db.GetActiveListingsInArea(tmpPoly).ToList();
            lstHouses.Items.Clear();
            lstHouses.Items.Add("Total Houses: " + tmpRes.Count());
            foreach(var house in tmpRes)
            {         
               lstHouses.Items.Add(house.StreetNum.ToString());
            }
         }
      }
      private string TxtCoords_to_PolyString()
      {
         string tmpCoords = txtCoords.Text.TrimEnd('|');
         string[] tmpPolyArr = tmpCoords.Split(' ','|',',');//splits the coordinate string into an array
         string tmpPolyStr = Arr_to_PolyString(tmpPolyArr);//converts array to WKT string
         tmpPolyStr = MakePolygonValid(tmpPolyStr);
         return tmpPolyStr;
      }
   }
}