/*
 * Copyright (C) 2016 The Qt Company Ltd.
 * Copyright (C) 2019 Konsulko Group
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *	  http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import QtQuick 2.6
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.0
import QtWebSockets 1.0
import QtLocation 5.9
import QtPositioning 5.6
import QtQuick.Window 2.13

ApplicationWindow {
	id: root
	visible: true

	width: Window.width
	height: Window.height

	title: qsTr("navigation")

    property real car_position_lat: fileOperation.getStartLatitude()
    property real car_position_lon: fileOperation.getStartLongitude()
    property real car_direction: 0  //North
    property real car_driving_speed: fileOperation.getCarSpeed()  // set Km/h
    property bool st_heading_up: false
    property real default_zoom_level : 18
    property real default_car_direction : 0
    property real car_accumulated_distance : 0
    property real positionTimer_interval : fileOperation.getUpdateInterval() // set millisecond
    property real car_moving_distance : (car_driving_speed / 3.6) / (1000/positionTimer_interval) // Metric unit

    Plugin {
            id: mapbox
            name: "mapbox"
            PluginParameter {
                name: "mapbox.access_token";
                value: fileOperation.getMapAccessToken()
            }
            PluginParameter {
                name: "mapbox.mapping.additional_map_ids"
                value: fileOperation.getMapStyleUrls()
            }
            PluginParameter {
                name: "mapbox.mapping.cache.directory"
                value: fileOperation.getCachePath("mapbox")
            }
    }
    Plugin {
            id: osm
            name: "osm"
            PluginParameter {
                name: "osm.mapping.host";
                value: "https://a.tile.openstreetmap.org/"
            }
            PluginParameter {
                name: "osm.mapping.cache.directory"
                value: fileOperation.getCachePath("osm")
            }
    }

    Connections {
        target: navigation

        onWaypointsEvent: {
            // only support one waypoint currently
            map.doSetWaypointsSlot(data.points[0].latitude, data.points[0].longitude, true)
        }

        onStatusEvent: {
            if (data.state == "stop") {
                // Slight hack here, if sts_guide != 0, btn_guidance.discardWaypoints
                // will trigger another stop, which can cancel a queued waypoint set,
                // so set it to 0 in advance.
                btn_guidance.sts_guide = 0
                map.doPauseSimulationSlot()
            }
            if (data.state == "start") {
                btn_guidance.startGuidance()
            }
        }
    }

    Map {
		id: map
        property int pathcounter : 0
        property int segmentcounter : 0
        property int waypoint_count: -1
		property int lastX : -1
		property int lastY : -1
		property int pressX : -1
		property int pressY : -1
		property int jitterThreshold : 30
        property variant currentpostion : QtPositioning.coordinate(car_position_lat, car_position_lon)
        property int last_segmentcounter : -1

        width: parent.width
        height: parent.height
        plugin: fileOperation.isOSMEnabled() ? osm : mapbox
        center: QtPositioning.coordinate(car_position_lat, car_position_lon)
        zoomLevel: default_zoom_level
        bearing: 0
        objectName: "map"

		GeocodeModel {
			id: geocodeModel
			plugin: map.plugin
			onStatusChanged: {
				if ((status == GeocodeModel.Ready) || (status == GeocodeModel.Error))
					map.geocodeFinished()
			}
			onLocationsChanged:
			{
				if (count == 1) {
					map.center.latitude = get(0).coordinate.latitude
					map.center.longitude = get(0).coordinate.longitude
				}
			}
        }
		MapItemView {
			model: geocodeModel
			delegate: pointDelegate
		}
		Component {
			id: pointDelegate

			MapCircle {
				id: point
				radius: 1000
				color: "#46a2da"
				border.color: "#190a33"
				border.width: 2
				smooth: true
				opacity: 0.25
				center: locationData.coordinate
			}
		}

		function geocode(fromAddress)
		{
			// send the geocode request
			geocodeModel.query = fromAddress
			geocodeModel.update()
		}
		
        MapQuickItem {
            id: poi
            sourceItem: Rectangle { width: 14; height: 14; color: "#e41e25"; border.width: 2; border.color: "white"; smooth: true; radius: 7 }
            coordinate {
                latitude: 36.136261
                longitude: -115.151254
            }
            opacity: 1.0
            anchorPoint: Qt.point(sourceItem.width/2, sourceItem.height/2)
        }
        MapQuickItem {
            sourceItem: Text{
                text: "Westgate"
                color:"#242424"
                font.bold: true
                styleColor: "#ECECEC"
                style: Text.Outline
            }
            coordinate: poi.coordinate
            z:11
            anchorPoint: Qt.point(-poi.sourceItem.width * 0.5, poi.sourceItem.height * 1.5)
        }
        MapQuickItem {
            id: car_position_mapitem
            property int isRotating: 0
            sourceItem: Image {
                id: car_position_mapitem_image
                width: 48
                height: 48
                source: "images/position02.svg"

                transform: Rotation {
                    id: car_position_mapitem_image_rotate
                    origin.x: car_position_mapitem_image.width/2
                    origin.y: car_position_mapitem_image.height/2
                    angle: car_direction
                }
            }
            anchorPoint: Qt.point(car_position_mapitem_image.width/2, car_position_mapitem_image.height/2)
            coordinate: map.currentpostion
            z:12
            states: [
                State {
                    name: "HeadingUp"
                    PropertyChanges { target: car_position_mapitem_image_rotate; angle: 0 }
                },
                State {
                    name: "NorthUp"
                    PropertyChanges { target: car_position_mapitem_image_rotate; angle: root.car_direction }
                }
            ]
            transitions: Transition {
                RotationAnimation {
                    properties: "angle";
                    easing.type: Easing.InOutQuad;
                    direction: RotationAnimation.Shortest;
                    duration: 200
                }
            }
        }

        MapQuickItem {
            id: icon_start_point
            anchorPoint.x: icon_start_point_image.width/2
            anchorPoint.y: icon_start_point_image.height
            z:11
            sourceItem: Image {
                id: icon_start_point_image
                width: 32
                height: 32
                source: "images/HEB_project_flow_icon_04_checkered_flag.svg"
            }
        }

        MapQuickItem {
            id: icon_end_point
            anchorPoint.x: icon_end_point_image.width/2
            anchorPoint.y: icon_end_point_image.height
            z:11
            sourceItem: Image {
                id: icon_end_point_image
                width: 32
                height: 32
                source: "images/Map_marker_icon_–_Nicolas_Mollet_–_Flag_–_Tourism_–_Classic.png"
            }
        }

        MapQuickItem {
            id: icon_segment_point
            anchorPoint.x: icon_segment_point_image.width/2 - 5
            anchorPoint.y: icon_segment_point_image.height/2 + 25
            z:11
            sourceItem: Image {
                id: icon_segment_point_image
                width: 64
                height: 64
                source: "images/Map_symbol_location_02.png"
            }
        }

		RouteModel {
			id: routeModel
            objectName: "routeModel"
            plugin: map.plugin
			query:  RouteQuery {
				id: routeQuery
			}
			onStatusChanged: {
				if (status == RouteModel.Ready) {
					switch (count) {
					case 0:
						// technically not an error
					//	map.routeError()
						break
					case 1:
						map.pathcounter = 0
						map.segmentcounter = 0
                        break
					}
				} else if (status == RouteModel.Error) {
				//	map.routeError()
				}
			}
		}
		
		Component {
			id: routeDelegate

			MapRoute {
				id: route
				route: routeData
				line.color: "#4658da"
				line.width: 10
                z:5
				smooth: true
                opacity: 0.8
			}
		}
		
		MapItemView {
			model: routeModel
			delegate: routeDelegate
		}

        MapItemView{
            model: markerModel
            delegate: mapcomponent
        }

        Component {
            id: mapcomponent
            MapQuickItem {
                id: icon_destination_point
                anchorPoint.x: icon_destination_point_image.width/4
                anchorPoint.y: icon_destination_point_image.height
                z:20
                coordinate: position

                sourceItem: Image {
                    id: icon_destination_point_image
                    width: 32
                    height: 32
                    source: "images/200px-Black_close_x.png"
                }
            }
        }

        function addDestination(coord){
            if( waypoint_count < 0 ){
                initDestination()
            }

            if(waypoint_count == 0)  {
                // set icon_start_point
                icon_start_point.coordinate = currentpostion
                map.addMapItem(icon_start_point)
            }

            if(waypoint_count < 9){
                routeQuery.addWaypoint(coord)
                waypoint_count += 1

                btn_guidance.sts_guide = 1
                btn_guidance.state = "Routing"

                var waypointlist = routeQuery.waypoints
                for(var i=1; i<waypoint_count; i++) {
                    markerModel.addMarker(waypointlist[i])
                }

                routeModel.update()
                navigation.broadcastRouteInfo(car_position_lat, car_position_lon,coord.latitude,coord.longitude)

                // update icon_end_point
                icon_end_point.coordinate = coord
                map.addMapItem(icon_end_point)
            }
        }

        function initDestination(startFromCurrentPosition){
            if (startFromCurrentPosition === undefined) startFromCurrentPosition = false
            routeModel.reset();
            console.log("initWaypoint")

            // reset currentpostion
            map.currentpostion = QtPositioning.coordinate(car_position_lat, car_position_lon)
            car_accumulated_distance = 0
            navigation.broadcastPosition(car_position_lat, car_position_lon,car_direction,car_accumulated_distance)

            routeQuery.clearWaypoints();
            routeQuery.addWaypoint(map.currentpostion)
            routeQuery.travelModes = RouteQuery.CarTravel
            routeQuery.routeOptimizations = RouteQuery.FastestRoute
            for (var i=0; i<9; i++) {
                routeQuery.setFeatureWeight(i, 0)
            }
            waypoint_count = 0
            pathcounter = 0
            segmentcounter = 0
            routeModel.update();
            markerModel.removeMarker();
            map.removeMapItem(markerModel);

            // remove MapItem
            map.removeMapItem(icon_start_point)
            map.removeMapItem(icon_end_point)
            map.removeMapItem(icon_segment_point)

            // update car_position_mapitem angle
            root.car_direction = root.default_car_direction

        }

		function calculateMarkerRoute()
		{
            var startCoordinate = QtPositioning.coordinate(car_position_lat, car_position_lon)

			console.log("calculateMarkerRoute")
			routeQuery.clearWaypoints();
            routeQuery.addWaypoint(startCoordinate)
            routeQuery.addWaypoint(mouseArea.lastCoordinate)
			routeQuery.travelModes = RouteQuery.CarTravel
			routeQuery.routeOptimizations = RouteQuery.FastestRoute
			for (var i=0; i<9; i++) {
				routeQuery.setFeatureWeight(i, 0)
			}
			routeModel.update();
		}

        // Calculate direction from latitude and longitude between two points
        function calculateDirection(lat1, lon1, lat2, lon2) {
            var curlat = lat1 * Math.PI / 180;
            var curlon = lon1 * Math.PI / 180;
            var taglat = lat2 * Math.PI / 180;
            var taglon = lon2 * Math.PI / 180;

            var Y  = Math.sin(taglon - curlon);
            var X  = Math.cos(curlat) * Math.tan(taglat) - Math.sin(curlat) * Math.cos(Y);
            var direction = 180 * Math.atan2(Y,X) / Math.PI;
            if (direction < 0) {
              direction = direction + 360;
            }
            return direction;
        }

        // Calculate distance from latitude and longitude between two points
        function calculateDistance(lat1, lon1, lat2, lon2)
        {
            var radLat1 = lat1 * Math.PI / 180;
            var radLon1 = lon1 * Math.PI / 180;
            var radLat2 = lat2 * Math.PI / 180;
            var radLon2 = lon2 * Math.PI / 180;

            var r = 6378137.0;

            var averageLat = (radLat1 - radLat2) / 2;
            var averageLon = (radLon1 - radLon2) / 2;
            var result = r * 2 * Math.asin(Math.sqrt(Math.pow(Math.sin(averageLat), 2) + Math.cos(radLat1) * Math.cos(radLat2) * Math.pow(Math.sin(averageLon), 2)));
            return Math.round(result);
        }

        // Setting the next car position from the direction and demonstration mileage
        function setNextCoordinate(curlat,curlon,direction,distance)
        {
            var radian = direction * Math.PI / 180
            var lat_per_meter = 111319.49079327358;
            var lat_distance = distance * Math.cos(radian);
            var addlat = lat_distance / lat_per_meter
            var lon_distance = distance * Math.sin(radian)
            var lon_per_meter = (Math.cos( (curlat+addlat) / 180 * Math.PI) * 2 * Math.PI * 6378137) / 360;
            var addlon = lon_distance / lon_per_meter
            map.currentpostion = QtPositioning.coordinate(curlat+addlat, curlon+addlon);
        }

		MouseArea {
			id: mouseArea
			property variant lastCoordinate
			anchors.fill: parent
			acceptedButtons: Qt.LeftButton | Qt.RightButton
			
			onPressed : {
				map.lastX = mouse.x
				map.lastY = mouse.y
				map.pressX = mouse.x
				map.pressY = mouse.y
				lastCoordinate = map.toCoordinate(Qt.point(mouse.x, mouse.y))
			}
			
			onPositionChanged: {
                if (mouse.button === Qt.LeftButton) {
					map.lastX = mouse.x
					map.lastY = mouse.y
				}
			}
			
			onPressAndHold:{
                if((btn_guidance.state !== "onGuide") && (btn_guidance.state !== "Routing"))
                {
                    if (Math.abs(map.pressX - mouse.x ) < map.jitterThreshold
                            && Math.abs(map.pressY - mouse.y ) < map.jitterThreshold) {
                        map.addDestination(lastCoordinate)
                    }
                }

			}
		}
        gesture.onFlickStarted: {
            btn_present_position.state = "Optional"
        }
        gesture.onPanStarted: {
            btn_present_position.state = "Optional"
        }
		function updatePositon()
		{
            if (!routeModel.get(0))
                return;

            if(pathcounter <= routeModel.get(0).path.length - 1){
                // calculate distance
                var next_distance = calculateDistance(map.currentpostion.latitude,
                                                      map.currentpostion.longitude,
                                                      routeModel.get(0).path[pathcounter].latitude,
                                                      routeModel.get(0).path[pathcounter].longitude);

                // calculate direction
                var next_direction = calculateDirection(map.currentpostion.latitude,
                                                        map.currentpostion.longitude,
                                                        routeModel.get(0).path[pathcounter].latitude,
                                                        routeModel.get(0).path[pathcounter].longitude);

                // calculate next cross distance
                var next_cross_distance = calculateDistance(map.currentpostion.latitude,
                                                            map.currentpostion.longitude,
                                                            routeModel.get(0).segments[segmentcounter].path[0].latitude,
                                                            routeModel.get(0).segments[segmentcounter].path[0].longitude);

                // map rotateAnimation cntrol
                if(root.st_heading_up) {
                    var is_rotating = 0;
                    var cur_direction = Math.floor(map.bearing);

                    // check is_rorating
                    if(cur_direction > Math.floor(next_direction)){
                        is_rotating = Math.floor(cur_direction - next_direction);
                    }else{
                        is_rotating = Math.floor(next_direction - cur_direction);
                    }

                    if(is_rotating > 180){
                        is_rotating = 360 - is_rotating;
                    }

                    // rotation angle case
                    if(is_rotating > 180){
                        // driving stop hard turn
                        root.car_moving_distance = 0;
                        rot_anim.duration = 1600;
                        rot_anim.easing.type = Easing.OutQuint;
                    } else if(is_rotating > 90){
                        // driving stop normal turn
                        root.car_moving_distance = 0;
                        rot_anim.duration = 800;
                        rot_anim.easing.type = Easing.OutQuart;
                    } else if(is_rotating > 60){
                        // driving slow speed normal turn
                        root.car_moving_distance = ((car_driving_speed / 3.6) / (1000/positionTimer_interval)) * 0.3;
                        rot_anim.duration = 400;
                        rot_anim.easing.type = Easing.OutCubic;
                    } else if(is_rotating > 30){
                        // driving half speed soft turn
                        root.car_moving_distance = ((car_driving_speed / 3.6) / (1000/positionTimer_interval)) * 0.5;
                        rot_anim.duration = 300;
                        rot_anim.easing.type = Easing.OutQuad;
                    } else {
                        // driving nomal speed soft turn
                        root.car_moving_distance = (car_driving_speed / 3.6) / (1000/positionTimer_interval);
                        rot_anim.duration = 200;
                        rot_anim.easing.type = Easing.OutQuad;
                    }
                }else{
                    // NorthUp
                    root.car_moving_distance = (car_driving_speed / 3.6) / (1000/positionTimer_interval);
                    rot_anim.duration = 200;
                    rot_anim.easing.type = Easing.OutQuad;
                }

                root.car_direction = next_direction;

                // set next coordidnate
                if(next_distance < (root.car_moving_distance * 1.5))
                {
                    map.currentpostion = routeModel.get(0).path[pathcounter]
                    car_accumulated_distance += next_distance
                    navigation.broadcastPosition(map.currentpostion.latitude, map.currentpostion.longitude,next_direction,car_accumulated_distance)
                    if(pathcounter < routeModel.get(0).path.length - 1){
                        pathcounter++
                    }
                    else
                    {
                        // Arrive at your destination
                        btn_guidance.sts_guide = 0
                        navigation.broadcastStatus("arrived")
                    }
                }else{
                    setNextCoordinate(map.currentpostion.latitude, map.currentpostion.longitude,next_direction,root.car_moving_distance)
                    if(pathcounter != 0){
                        car_accumulated_distance += root.car_moving_distance
                    }
                    navigation.broadcastPosition(map.currentpostion.latitude, map.currentpostion.longitude,next_direction,car_accumulated_distance)
                }

                if(btn_present_position.state === "Flowing")
                {
                    // update map.center
                    map.center = map.currentpostion
                }
                rotateMapSmooth()

                // report a new instruction if current position matches with the head position of the segment
                if(segmentcounter <= routeModel.get(0).segments.length - 1){
                     if(next_cross_distance < 2){
                        progress_next_cross.setProgress(0)
                        if(segmentcounter < routeModel.get(0).segments.length - 1){
                            segmentcounter++
                        }
                        if(segmentcounter === routeModel.get(0).segments.length - 1){
                            img_destination_direction.state = "12"
                            map.removeMapItem(icon_segment_point)
                        }else{
                            img_destination_direction.state = routeModel.get(0).segments[segmentcounter].maneuver.direction
                            icon_segment_point.coordinate = routeModel.get(0).segments[segmentcounter].path[0]
                            map.addMapItem(icon_segment_point)
                        }
                    }else{
                        if(next_cross_distance <= 330 && last_segmentcounter != segmentcounter) {
                            last_segmentcounter = segmentcounter
                            guidanceModule.guidance(routeModel.get(0).segments[segmentcounter].maneuver.instructionText)
                        }
                        // update progress_next_cross
                        progress_next_cross.setProgress(next_cross_distance)
                    }
                }
            }
		}

        function doGetRouteInfoSlot(){
            if(btn_guidance.sts_guide == 0){ // idle
                navigation.broadcastPosition(car_position_lat, car_position_lon,car_direction,car_accumulated_distance);
            }else if(btn_guidance.sts_guide == 1){ // Routing
                navigation.broadcastPosition(car_position_lat, car_position_lon,car_direction,car_accumulated_distance);
                navigation.broadcastRouteInfo(car_position_lat, car_position_lon,routeQuery.waypoints[1].latitude,routeQuery.waypoints[1].longitude);
            }else if(btn_guidance.sts_guide == 2){ // onGuide
                navigation.broadcastRouteInfo(car_position_lat, car_position_lon,routeQuery.waypoints[1].latitude,routeQuery.waypoints[1].longitude);
            }
        }

        function rotateMapSmooth(){
            if(root.st_heading_up){
                map.state = "none"
                map.state = "smooth_rotate"
            }else{
                map.state = "smooth_rotate_north"
            }
        }

        function stopMapRotation(){
            map.state = "none"
            rot_anim.stop()
        }

        function doPauseSimulationSlot(){
            btn_guidance.discardWaypoints();
        }

        function doGetAllRoutesSlot(){
            return routeModel.count;
        }

        function doSetWaypointsSlot(latitude,longitue,startFromCurrentPosition){

            btn_guidance.discardWaypoints(startFromCurrentPosition);

            if(btn_present_position.state === "Optional"){
                map.center = map.currentpostion
                btn_present_position.state = "Flowing"
            }

            map.addDestination(QtPositioning.coordinate(latitude,longitue))
        }

        states: [
            State {
                name: "none"
            },
            State {
                name: "smooth_rotate"
                PropertyChanges { target: map; bearing: root.car_direction }
            },
            State {
                name: "smooth_rotate_north"
                PropertyChanges { target: map; bearing: 0 }
            }
        ]

        transitions: Transition {
            NumberAnimation { properties: "center"; easing.type: Easing.InOutQuad }
            RotationAnimation {
                id: rot_anim
                property: "bearing"
                direction: RotationAnimation.Shortest
                easing.type: Easing.OutQuad
                duration: 200
            }
        }
    }
		
    BtnPresentPosition {
        id: btn_present_position
        anchors.right: parent.right
        anchors.rightMargin: 125
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 175
    }

	BtnMapDirection {
        id: btn_map_direction
        anchors.top: parent.top
        anchors.topMargin: 25
        anchors.left: parent.left
        anchors.leftMargin: 25
	}

    BtnGuidance {
        id: btn_guidance
        anchors.top: parent.top
        anchors.topMargin: 25
        anchors.right: parent.right
        anchors.rightMargin: 125
	}

	BtnShrink {
        id: btn_shrink
        anchors.left: parent.left
        anchors.leftMargin: 25
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 325
	}

	BtnEnlarge {
        id: btn_enlarge
        anchors.left: parent.left
        anchors.leftMargin: 25
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 175
	}

	ImgDestinationDirection {
        id: img_destination_direction
        anchors.top: parent.top
        anchors.topMargin: 25
        anchors.left: parent.left
        anchors.leftMargin: 150
	}

    ProgressNextCross {
        id: progress_next_cross
        anchors.top: parent.top
        anchors.topMargin: 25
        anchors.left: img_destination_direction.right
        anchors.leftMargin: 20
	}

    Image {
        visible: map.plugin.name === "mapbox"
        anchors.left: parent.left
        anchors.leftMargin: 35
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10
        scale: 1.5
        source: "images/mapbox_logo.svg"
    }

    Label {
        visible: map.plugin.name === "mapbox"
        font.pixelSize: 18
        anchors.right: parent.right
        anchors.rightMargin: 25
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10
        text: "<a href='https://www.mapbox.com/about/maps'>© Mapbox | </a> <a href='http://www.openstreetmap.org/copyright'>© OpenStreetMap | </a> <a href='https://www.mapbox.com/map-feedback/'><strong>Improve this map</strong>"
	}
}
