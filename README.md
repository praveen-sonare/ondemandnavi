# navigation

#reference

https://doc-snapshots.qt.io/qt5-5.9/qtlocation-mapviewer-example.html

#build step

source /SDK_PATH/environment-setup-aarch64-agl-linux

mkdir build

cd build

qmake ../

make

#configuration

NOTE: To use OpenStreetMaps instead of MapBox you should set
enableOSM to true in the configuration sample below

Please set mapAccessToken, mapStyleUrl, speed,
interval, latitude and longitude in JSON format
in /etc/naviconfig.ini

mapAccessToken sets Access token provided by Mapbox.
speed sets vehicle speed in km / h.
interval sets the screen update interval in milliseconds.
latitude, longitude sets the current position at application start.
mapStyleUrls sets Mapbox style URLs.

example
{
	"mapAccessToken":"pk.***********",
	"speed":60,
	"interval":100,
	"latitude":36.1363,
	"longitude":-115.151,
	"mapStyleUrls":"mapbox://styles/mapbox/dark-v9",
	"enableOSM:false
}
