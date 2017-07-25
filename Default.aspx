<%@ Page Title="Home Page" Language="C#" AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="WebApplication2._Default" %>

<%@ Register Assembly="DevExpress.Web.v16.1, Version=16.1.11.0, Culture=neutral, PublicKeyToken=b88d1754d700e49a" Namespace="DevExpress.Web" TagPrefix="dx" %>


<!DOCTYPE html>
<html>
<head>
    <title></title>
    <style>
        #gvHouses {
            margin: 0 auto;
        }

        .controlUI {
            border: 1px solid #f48131;
            border-radius: 3px;
            box-shadow: 0 2px 6px rgba(0,0,0,.3);
            cursor: pointer;
            margin-bottom: 10px;
            text-align: center;
            padding-bottom: 0px;
            padding-top: 0px;
            position: relative;
            color: rgb(255,255,255);
            font-family: Roboto,Arial,sans-serif;
            font-size: 16px;
            line-height: 38px;
            padding-left: 5px;
            padding-right: 5px;
        }



        #btnClear {
            -webkit-animation-duration: 0.2s;
            transition-duration: 0.2s;
            background-color: #fff;
            color: #f48131;
        }

        #btnDraw {
            -webkit-animation-duration: 0.2s;
            transition-duration: 0.2s;
            background-color: #f48131;
        }

        #btnSave {
            -webkit-animation-duration: 0.2s;
            transition-duration: 0.2s;
            background-color: #f48131;
            margin-right: 70px;
            top: 0px;
            left: 0px;
        }

        #btnSearch {
            -webkit-animation-duration: 0.2s;
            transition-duration: 0.2s;
            background-color: #f48131;
        }

        #btnShowHomes {
            -webkit-animation-duration: 0.2s;
            transition-duration: 0.2s;
            background-color: #f48131;
            margin-top: 10px;
            margin-bottom: 0px;
        }

        #btnClear:hover {
            background-color: #e5e6f4;
        }

        #btnDraw:hover {
            background-color: #bf6323;
        }

        #btnSave:hover {
            background-color: #bf6323;
        }

        #btnSearch:hover {
            background-color: #bf6323;
        }

        #btnShowHomes:hover {
            background-color: #bf6323;
        }

        #map {
            height: 940px;
            width: 1500px
        }

        #mapControls {
            margin-left: 30px;
        }
    </style>


    <script type="text/javascript" src="Scripts/jquery-1.10.2.min.js"></script>

</head>
<body>
    <form id="bleh" runat="server">
        <div id="mapControls">
            <input type="button" id="btnClear" class="controlUI" value="Clear Map" title="click to clear map of polygons and markers" onclick="clearOverlays();" />
            <input type="button" class="controlUI" id="btnDraw" value="Reload Neighborhood Area" title="click to reload the selected neighborhood area"
                onclick=" drawNei();" />
            <asp:Button CssClass="controlUI" ID="btnSave" Title="click to save the area on the map to the selected neighborhood"
                Text="Save Area" runat="server" OnClick="btnSave_Click" OnClientClick="saveClick=true;" />

            <div hidden="hidden">
                <asp:TextBox ID="txtCoords" ClientIDMode="Static" Width="100%" runat="server" /><br />
            </div>
        </div>

        <div id="searchUI">
            <asp:Button ID="btnSearch" CssClass="controlUI" Text="Search Homes Within Area" title="click to search for homes within the area on the map" runat="server" OnClick="btnSearch_Click" OnClientClick="saveClick=false;" />
        </div>

        <div id="listUI">
            <asp:ListBox ID="lstNeighborhoods" runat="server" />
            <asp:ListBox ID="lstHouses" runat="server"/>
        </div>
        

    <div class="container">
        <div id="map">

        
         
        </div>
    </div>

    </form>

    <script>


        function InitializeRequest(sender, args) {

        }

        // fires after the partial update of UpdatePanel
        function EndRequest(sender, args) {
            polygon = null;
            initMap();
        }

        var map;
        var bounds;
        var permaTxt;
        var houses = false;
        var drawn = false;
        var polygon;
        var marker;
        var markers = [];
        var contentString = "";
        var markLat;
        var markLon;
        var saveClick = true;
        var myCenter;
        var ZIP_MAPTYPE_ID = 'ziphybrid'

        function initMap() {

            map = new google.maps.Map(document.getElementById('map'), {//(FROM: Google) initializes map
                center: { lat: 30, lng: -80 },
                zoom: 4
            });

            map.controls[google.maps.ControlPosition.TOP].push(mapControls);
            map.controls[google.maps.ControlPosition.BOTTOM].push(searchUI);
            map.controls[google.maps.ControlPosition.RIGHT].push(listUI);


            if ($("#txtNeiMarker").val() != null) {
                var neiCoord = $("#txtNeiMarker").val().split('|');
                var neiMark = new google.maps.LatLng(neiCoord[0], neiCoord[1]);

                myCenter = neiMark;

                map.setCenter(myCenter);
                map.setZoom(15);

                var marker = new google.maps.Marker({
                    position: myCenter,
                    map: map,
                    icon: 'https://trinity.truehomesusa.com/emails/images/th_Marker02.png',
                    label: neiCoord[2]
                });
            }



            houses = false;
            drawn = false;

            bounds = new google.maps.LatLngBounds();

            permaTxt = $("#permaCoords").val();

            var drawingManager = new google.maps.drawing.DrawingManager({//(FROM: Google) initializes drawingManager, so we're able to draw polygons
                drawingMode: google.maps.drawing.OverlayType.POLYGON,
                drawingControl: true,
                drawingControlOptions: {
                    position: google.maps.ControlPosition.TOP_LEFT,
                    drawingModes: [
                        google.maps.drawing.OverlayType.POLYGON
                    ]
                },
                polygonOptions: {
                    fillColor: '#DC7633'
                }

            });

            drawingManager.setMap(map);

            drawingManager.addListener('overlaycomplete', function (event) {
                contentString = $("#txtCoords").val();
                if ($("#txtCoords").val() != "")
                    contentString += " ";

                polygon = event.overlay;//polygon = the polygon drawn on the map
                polygon.setEditable(false);
                markers.push(polygon);

                var vertices = polygon.getPath();
                google.maps.event.addListener(vertices, 'set_at', showCoords);
                google.maps.event.addListener(vertices, 'insert_at', showCoords);
                google.maps.event.addListener(polygon.getPath(), 'remove_at', showCoords);

                for (var i = 0; i < vertices.getLength(); i++) {
                    var xy = vertices.getAt(i);
                    contentString += xy.lat() + ',' + xy.lng() + "|";//put the coordinates in a textbox
                }
                if (vertices.getAt(vertices.getLength()) != vertices.getAt(0)) {
                    var tmpXY = vertices.getAt(0);
                    contentString += tmpXY.lat() + ',' + tmpXY.lng();
                }
                $("#txtCoords").val(contentString);
            });

            /*google.maps.event.addListenerOnce(map, 'idle', function () {
    
                google.maps.event.trigger(map, 'resize');
    
                map.setCenter(myCenter);
    
                if (saveClick) {
                    drawNei();
                } else {
                    showHomes();
                }
                saveClick = true;
            });*/
        }

        function clearOverlays() {
            while (markers.length) {
                markers.pop().setMap(null);//remove markers and polygons from the map, but does not delete the object

            }
            houses = false;
            drawn = false;
            contentString = "";
            if (polygon != null) {

            }
            $("#txtCoords").val(contentString);
            $("#txtMarkers").val("");

            polygon = null;
        }

        function showCoords(event) {
            contentString = "";
            //loop through each vertex and get the coordinate
            for (var i = 0; i < this.getLength(); i++) {
                var xy = this.getAt(i);
                contentString += xy.lat() + ',' + xy.lng() + "|";//add them to string for textbox
            }
            if (this.getAt(this.getLength()) != this.getAt(0)) {
                var tmpXY = this.getAt(0);
                contentString += tmpXY.lat() + ',' + tmpXY.lng();
            }
            $("#txtCoords").val(contentString);


        }

        function drawNei() {
            if ($("#permaCoords").val() == "") {
                //alert("Selected Neighborhood does not have an area to display");
            } else {
                if (drawn) {

                } else {
                    var permaTxt = $("#permaCoords").val();
                    var tmpTxt = $("#txtCoords").val();

                    if (tmpTxt == "") {
                        $("#txtCoords").val(permaTxt);
                    } else {
                        if (tmpTxt == permaTxt) {

                        } else {
                            $("#txtCoords").val(tmpTxt + " " + permaTxt);
                        }
                    }
                    var area = $("#permaCoords").val();
                    drawArea(area);
                }
                map.setCenter(polygonCenter(polygon));
                map.fitBounds(bounds);
            }

        }


        function showHomes() {
            if ($("#txtCoords").val() == "") {

            } else {
                if ($("#txtMarkers").val() == "") {
                    alert("no homes found within area")
                } else {
                    if (houses) {

                    } else {
                        var tmp = $("#txtMarkers").val().split('|');
                        var tmpMarkers = tmp.toString().split(',');
                        for (var i = 0; i < tmpMarkers.length; i += 2) {
                            var coords = new google.maps.LatLng(tmpMarkers[i], tmpMarkers[i + 1]);
                            var marker = new google.maps.Marker({
                                position: coords,
                                map: map,
                                icon: 'https://maps.gstatic.com/intl/en_us/mapfiles/markers2/measle_blue.png'
                            });

                            markers.push(marker);
                            bounds.extend(coords);
                        }

                    }
                }
                houses = true;
                var area = $("#txtCoords").val();
                drawArea(area)
                map.fitBounds(bounds);
                drawn = true;
            }


        }

        function drawArea(area) {
            area = area.split(' ');

            for (var i = 0; i < area.length; i += 1) {
                var polyArr = [];
                var poly = area[i].split("|");
                var tmpPoly = poly.toString().split(",");
                for (var j = 0; j < tmpPoly.length - 2; j += 2) {
                    var coord = new google.maps.LatLng(tmpPoly[j], tmpPoly[j + 1]);
                    polyArr.push(coord);
                    bounds.extend(coord);
                }
                polygon = new google.maps.Polygon({
                    paths: [polyArr],//reads array created in the above for loop in the format [{lat:32, lng:65},{}...]
                    fillColor: '#FF0000',
                    fillOpacity: 0.35,
                    editable: false
                });
                polygon.setMap(map);
                markers.push(polygon);
                google.maps.event.addListener(polygon.getPath(), 'set_at', showCoords);
                google.maps.event.addListener(polygon.getPath(), 'insert_at', showCoords);
                google.maps.event.addListener(polygon.getPath(), 'remove_at', showCoords);
                drawn = true;
            }
        }

        function polygonCenter(poly) {
            var lowx,
                highx,
                lowy,
                highy,
                lats = [],
                lngs = [],
                vertices = poly.getPath();

            for (var i = 0; i < vertices.length; i++) {
                lngs.push(vertices.getAt(i).lng());
                lats.push(vertices.getAt(i).lat());
            }

            lats.sort();
            lngs.sort();
            lowx = lats[0];
            highx = lats[vertices.length - 1];
            lowy = lngs[0];
            highy = lngs[vertices.length - 1];
            center_x = lowx + ((highx - lowx) / 2);
            center_y = lowy + ((highy - lowy) / 2);
            return (new google.maps.LatLng(center_x, center_y));
        }


    </script>

    <script async defer
        src="https://maps.googleapis.com/maps/api/js?key=AIzaSyB2l0sqvMlfYTX683rmcK4zrYG5rPOOE7w&libraries=drawing&v=3&callback=initMap">
    </script>


    <p>&nbsp;</p>
</body>
</html>
