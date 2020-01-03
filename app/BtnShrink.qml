import QtQuick 2.0
import QtQuick.Controls 1.5

Item {
	Button {
		id: btn_shrink
		width: 100
		height: 100

        function zoomDown() {
		map.zoomLevel -= 1
		if(map.zoomLevel != default_zoom_level) {
			btn_present_position.state = "Optional"
		}
	}

        onClicked: { zoomDown() }

		Image {
			id: image
			width: 92
			height: 92
			anchors.verticalCenter: parent.verticalCenter
			anchors.horizontalCenter: parent.horizontalCenter
            source: "images/240px-Antu_file-zoom-out.png"
		}
	}
}
