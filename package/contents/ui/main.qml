/*
*    SPDX-FileCopyrightText: %{CURRENT_YEAR} %{AUTHOR} <%{EMAIL}>
*    SPDX-License-Identifier: LGPL-2.1-or-later
*/

import QtQuick 2.3
import QtQuick.Layouts 1.0
import QtQuick.Controls 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.kirigami 2.19 as Kirigami

import QtWebEngine 1.9

Item {
	id: root
	property bool themeMismatch: false;
	property int nextReloadTime: 0;
	property int reloadRetries: 0;
	property int maxReloadRetiries: 25;
	property bool loadedsuccessfully:false;

	Plasmoid.compactRepresentation: CompactRepresentation {}

	Plasmoid.fullRepresentation: ColumnLayout {
		anchors.fill: parent

		Layout.minimumWidth: 128 * PlasmaCore.Units.devicePixelRatio
		Layout.minimumHeight:  256 * PlasmaCore.Units.devicePixelRatio
		Layout.preferredWidth: 340 * PlasmaCore.Units.devicePixelRatio
		Layout.preferredHeight: 561 * PlasmaCore.Units.devicePixelRatio

		//-----------------------------  Helpers ------------------
		// Added workaround by @zontafil thank you!
		
		Timer {
			id: exposeTimer

			interval: plasmoid.configuration.focusInterval ? plasmoid.configuration.focusInterval : 0
			running: false
			onTriggered: {
				gptWebView.forceActiveFocus();
				gptWebView.focus=true;
				gptWebView.runJavaScript("document.userScripts.setInputFocus();");
				console.log("Plasmoid exposeTimer :"+plasmoid.expanded )
			}
		}

		Timer {
			id: reloadTimer

			interval: 1000
			running:  !plasmoid.expand
			onTriggered: if(	!loadedsuccessfully &&
								!plasmoid.expanded &&
								Date.now() > root.nextReloadTime &&
								root.reloadRetries < root.maxReloadRetiries ){
					console.log("Failed to load Bard Google page, reloading as we are hidden..");
					root.reloadRetries +=1;
					root.nextReloadTime = Math.min(Date.now() + 1000 * (2**root.reloadRetries) , plasmoid.configuration.maxReloadTime * 1000);
					gptWebView.reload();
			}
		}

		Connections {
			target: plasmoid
			function onActivated() {
				console.log("Plasmoid revealed to user")
			}
			function onStatusChanged() {
				console.log("Plasmoid status changed "+plasmoid.status)
			}
			function hideOnWindowDeactivateChanged() {
				console.log("Plasmoid hideOnWindowDeactivateChanged changed")
			}
			function onExpandedChanged() {
				if(gptWebView && plasmoid.expanded) {
					if(gptWebView.LoadStatus == WebEngineView.LoadFailedStatus) {
						gptWebView.reload();
					}

					exposeTimer.start();
				}
				if(!plasmoid.expanded && root.themeMismatch && plasmoid.configuration.matchTheme ) {
					root.themeMismatch = false;
					gptWebView.reloadAndBypassCache();
				}
				console.log("Plasmoid onExpandedChanged :"+plasmoid.expanded )
			}
		}

		//------------------------------------- UI -----------------------------------------

		ColumnLayout {
			spacing: Kirigami.Units.mediumSpacing

			PlasmaExtras.PlasmoidHeading {
				Layout.fillWidth: true

				ColumnLayout {					
					anchors.fill: parent
					Layout.fillWidth: true

					RowLayout {
						Layout.fillWidth: true

						RowLayout {
							Layout.fillWidth: true
							spacing: Kirigami.Units.mediumSpacing

							PlasmaComponents.ToolButton {
								text: i18n("Regresar a Bard")
								visible: !gptWebView.url.toString().match(/bard\.google\.com\/(|chat|auth)/);
								enabled: visible
								icon.name: "draw-arrow-back"
								display: PlasmaComponents.ToolButton.IconOnly
								PlasmaComponents.ToolTip.text: text
								PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
								PlasmaComponents.ToolTip.visible: hovered
								onClicked: gptWebView.url = "https://bard.google.com/";
							}

							Kirigami.Heading {
								id: titleText
								Layout.alignment: Qt.AlignCenter
								Layout.fillWidth: true
								verticalAlignment: Text.AlignVCenter
								text: i18n("Bard Google")
								color: theme.textColor
							}
						}

						PlasmaComponents.ToolButton {
							text: i18n("Debug")
							checkable: true
							checked: gptWebViewInspector && gptWebViewInspector.enabled
							visible: Qt.application.arguments[0] == "plasmoidviewer" || plasmoid.configuration.debugConsole
							enabled: visible
							icon.name: "format-text-code"
							display: PlasmaComponents.ToolButton.IconOnly
							PlasmaComponents.ToolTip.text: text
							PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
							PlasmaComponents.ToolTip.visible: hovered
							onToggled: {
								gptWebViewInspector.visible = !gptWebViewInspector.visible;
								gptWebViewInspector.enabled = visible || gptWebViewInspector.visible
							}
						}

						PlasmaComponents.ToolButton {
							id: proButton
							checkable: true
							checked: proLinkContainer.visible
							text: i18n("Im a Pro")
							visible: gptWebView.url.toString().match(/bard\.google\.com\/auth/);
							icon.name: "x-office-contact"
							display: PlasmaComponents.ToolButton.IconOnly
							PlasmaComponents.ToolTip.text: text
							PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
							PlasmaComponents.ToolTip.visible: hovered
							onToggled: proLinkContainer.visible = !proLinkContainer.visible;
						}

						PlasmaComponents.ToolButton {
							id: refreshButton
							text: i18n("Recargar")
							icon.name: "view-refresh"
							display: PlasmaComponents.ToolButton.IconOnly
							PlasmaComponents.ToolTip.text: text
							PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
							PlasmaComponents.ToolTip.visible: hovered
							onClicked: gptWebView.reload();
						}

						PlasmaComponents.ToolButton {
							id: pinButton
							checkable: true
							checked: plasmoid.configuration.pin
							icon.name: "window-pin"
							text: i18n("Fijar")
							display: PlasmaComponents.ToolButton.IconOnly
							PlasmaComponents.ToolTip.text: text
							PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
							PlasmaComponents.ToolTip.visible: hovered
							onToggled: plasmoid.configuration.pin = checked
						}
					}

					RowLayout {
						id: proLinkContainer
						Layout.fillWidth: true
						visible: false;

						PlasmaComponents.TextField {
							id: proLinkField

							enabled: proLinkContainer.visible
							Layout.fillWidth: true

							placeholderText: i18n("Paste the accesss link that was send to your email.")
							text: ""
						}

						PlasmaComponents.Button {
							enabled: proLinkContainer.visible
							icon.name: "go-next"
							onClicked:  {
								gptWebView.url = proLinkField.text;
								proLinkContainer.visible= false;
							}
						}
					}
				}
			}

			//-------------------- Connections  -----------------------

			Binding {
				target: plasmoid
				property: "hideOnWindowDeactivate"
				value: !plasmoid.configuration.pin
			}
		}


		WebEngineView {
				// anchors.fill: parent
				// Layout.fillHeight: true
				// Layout.fillWidth: true

				id: gptWebView
				focus: true
				width: 340
				height: 561
				url: "https://bard.google.com/"

				profile: WebEngineProfile {
					id: chatGptProfile
					storageName: "bard-google"
					offTheRecord: false
					httpCacheType: WebEngineProfile.DiskHttpCache
					persistentCookiesPolicy: WebEngineProfile.ForcePersistentCookies
					userScripts: [
						WebEngineScript {
							injectionPoint: WebEngineScript.DocumentCreation
							name: "helperFunctions"
							worldId: WebEngineScript.MainWorld
							sourceUrl: "./js/helper_functions.js"
						}
					]
				}

				settings.javascriptCanAccessClipboard: plasmoid.configuration.allowClipboardAccess

				onLoadingChanged: {
					if(WebEngineView.LoadSucceededStatus === loadRequest.status) {
						root.reloadRetries = 0;
						let themeLightness = (isDark(theme.backgroundColor) ? 'dark' : 'light') ;

						gptWebView.runJavaScript("document.userScripts.setConfig("+JSON.stringify(plasmoid.configuration)+");");
						gptWebView.runJavaScript("document.userScripts.setSendOnEnter();");
						gptWebView.runJavaScript("document.userScripts.getTheme();",function(theme) {
							if( !plasmoid.expanded && plasmoid.configuration.matchTheme && (!theme ||  theme !== themeLightness)) {
								gptWebView.runJavaScript("document.userScripts.setTheme('"+themeLightness+"');");
								gptWebView.relreloadAndBypassCacheoad();
							} else if(plasmoid.configuration.matchTheme && theme !== themeLightness) {
								root.themeMismatch = true;
							}
						});
						gptWebView.runJavaScript("document.userScripts.setTheme('"+themeLightness+"');");
					}


					loadedsuccessfully = 	( loadRequest.status == WebEngineLoadRequest.LoadSucceededStatus && (gptWebView.loadProgress == 100 || gptWebView.loadProgress == 0))
										&&
											( !gptWebView.loading )

				}

				onJavaScriptConsoleMessage: if(Qt.application.arguments[0] == "plasmoidviewer") {
					console.log("Bard-Google: " + message);
				}

				onNavigationRequested: if(request.navigationType == WebEngineNavigationRequest.LinkClickedNavigation) {
					if(request.url.toString().match(/https?\:\/\/bard\.google\.com/)) {
						gptWebView.url = request.url;
					} else {
						Qt.openUrlExternally(request.url);
						request.action = WebEngineNavigationRequest.IgnoreRequest;
					}
				}

				function isDark(color) {
					let luminance = 0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b;
					return (luminance < 0.5);
				}
			}
			WebEngineView {
				id:gptWebViewInspector
				enabled: false
				visible: false
				z:100
				height:parent.height /2

				Layout.fillWidth:false
				Layout.alignment: Qt.AlignTop
				inspectedView:enabled ? gptWebView : null
			}
	}
}

