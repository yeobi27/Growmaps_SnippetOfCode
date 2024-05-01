import 'package:freegrow_backend/freegrow_backend.dart';

class FreeGrowMapboxJavaScript {
  String initialData(
      {required LatLngDTO? centerLatLng,
        required double? initialMobileZoom,
        required double? initialWebZoom,
        required double? initBearing,
        required double? minZoom,
        required double? maxZoom,
        required bool? isBoothNumberDisplayed,
        required bool mobileResolution,
        required bool kioskMode}) {
    return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Extrude polygons for 3D indoor mapping</title>
<meta name="viewport" content="initial-scale=1,maximum-scale=1,user-scalable=no">
<link href="https://api.mapbox.com/mapbox-gl-js/v3.3.0/mapbox-gl.css" rel="stylesheet">
<script src="https://api.mapbox.com/mapbox-gl-js/v3.3.0/mapbox-gl.js"></script>
<script src="https://cdn.jsdelivr.net/npm/@turf/turf@latest"></script>
<style>
body { margin: 0; padding: 0; overflow: hidden;  }
#map { position: absolute; top: 0; bottom: 0; width: 100%; height:100%; padding-bottom:5ex }
</style>
</head>
<body>
<div id="map"></div>
<script>

var initialZoom = ${mobileResolution == true} ? $initialMobileZoom : $initialWebZoom;
var initialPitch = 0; // 초기 pitch 값
var initialBearing = $initBearing; // 초기 bearing 값
var initialSpeed = 0.8; // 카메라 이동시 디폴트 값
var initialDisplayMapNumber = $isBoothNumberDisplayed;

mapboxgl.accessToken = '토큰입니다~시크릿시크릿';	
const map = new mapboxgl.Map({
container: 'map',
// Choose from Mapbox's core styles, or make your own style with Mapbox Studio
// style: 'mapbox://styles/mapbox/streets-v12',
// style: 'mapbox://styles/mapbox/empty-v9',
style: 'mapbox://styles/mapbox/light-v11',
maxTileCacheSize: 0,

center: [${centerLatLng?.lng}, ${centerLatLng?.lat}],
zoom : initialZoom,
minZoom: $minZoom,
maxZoom: $maxZoom,
trackResize: true,
pitch: initialPitch,
bearing: initialBearing,
antialias: true,
attributionControl: false,
});

// ==================================================================================================
// 공용사용 멤버변수&함수
// ==================================================================================================
var defaultMarkerSize = 0.4; // 기본 심볼 마커 크기, 출발,도착,경유지, 선택핀 관련
var initClickedMarkerSize = 0.1; // 초기화 핀클릭 마커 크기
var clickedMarkerSize = 0.3; // 핀 클릭된 마커 크기
var initCandidateMarkerSize = 0.1; // 핀 카테고리 마커 크기
var clickedCandidateMarkerSize = 0.25; // 클릭된 카테고리 마커 크기
var startPointMarkerSize = 0.26;
var endPointMarkerSize = 0.26;
var stopPlaceMarkerSize = 0.26;
var dotMarkerSize = 0.3;
var normalLayerID = 'points';
var startLayerID = 'start-point-layer';
var endLayerID = 'end-point-layer';
var stopOverLayerID = 'stopover-point-layer';
var candidateLayerID = 'candidate-point-layer';
var selectedPinLayerID = 'selected-pin-layer';
var grayLineLayerIDs = ['grayLine1','grayLine2','grayLine3'];
var growmapsLineLayerIDs = ['growmapsLine1','growmapsLine2','growmapsLine3'];
var lineBackgroundSourceID = 'line-background-source';
var fonts = ['Noto Sans SemiCondensed', 'Noto Sans SemiCondensed', 'Noto Sans SemiCondensed'];
var layersToQuery = [normalLayerID, startLayerID, endLayerID, stopOverLayerID, candidateLayerID];

// 한국어 URL
var pinImageUrl           = 'https://firebasestorage.googleapis.com/v0/b/grow-maps-platform.appspot.com/o/growmaps_ex_icon%2FPin.png?alt=media&token=f1ccb8b4-41b5-4896-aa1f-9b5903cd878c';
var pinPressedImageUrl    = 'https://firebasestorage.googleapis.com/v0/b/grow-maps-platform.appspot.com/o/growmaps_ex_icon%2FPin_pressed.png?alt=media&token=a2762755-03da-43ff-a889-09760ddfc26a';
var boothImageUrl         = 'https://firebasestorage.googleapis.com/v0/b/grow-maps-platform.appspot.com/o/growmaps_ex_icon%2Fbooth.png?alt=media&token=329378b3-5ece-4dc2-9f53-33e5d90e3e39';
var dotImageUrl           = 'https://firebasestorage.googleapis.com/v0/b/grow-maps-platform.appspot.com/o/growmaps_ex_icon%2Fdot.png?alt=media&token=8653ed33-4613-4c2c-89b4-54f99dccde06';
var specialBoothImageUrl  = 'https://firebasestorage.googleapis.com/v0/b/grow-maps-platform.appspot.com/o/growmaps_ex_icon%2Fbooth-1.png?alt=media&token=9047f1ca-3ff6-4eb2-a00f-2af989a121e5'; 
var entranceImageUrl      = 'https://firebasestorage.googleapis.com/v0/b/grow-maps-platform.appspot.com/o/growmaps_ex_icon%2Fentrance.png?alt=media&token=9ccf6ad5-0a68-40d0-bfac-9082f6c7d8c8';
var cafeteriaImageUrl     = 'https://firebasestorage.googleapis.com/v0/b/grow-maps-platform.appspot.com/o/growmaps_ex_icon%2Fcafeteria.png?alt=media&token=8cef203a-0cd1-482f-ade0-141005ee26d6';
var conferenceImageUrl    = 'https://firebasestorage.googleapis.com/v0/b/grow-maps-platform.appspot.com/o/growmaps_ex_icon%2Fconference.png?alt=media&token=cec8a201-35cd-4025-92ab-f7cbf58c6111';
var endImageUrl           = 'https://firebasestorage.googleapis.com/v0/b/grow-maps-platform.appspot.com/o/growmaps_ex_icon%2Fend.png?alt=media&token=a0d4c1a9-932e-44b7-b69a-2482cc8a64de';
var startImageUrl         = 'https://firebasestorage.googleapis.com/v0/b/grow-maps-platform.appspot.com/o/growmaps_ex_icon%2Fstart.png?alt=media&token=8c69548d-11f9-49ee-9401-d368cf2593e1';
var myPositionImageUrl    = 'https://firebasestorage.googleapis.com/v0/b/grow-maps-platform.appspot.com/o/growmaps_ex_icon%2FmyPosition.png?alt=media&token=64c7f70c-8b34-4021-bbb2-0f5a27c9b5bb';
var meetingRoomImageUrl   = 'https://firebasestorage.googleapis.com/v0/b/grow-maps-platform.appspot.com/o/growmaps_ex_icon%2Fmeetingroom.png?alt=media&token=dc0d828e-5d43-462a-87c6-e6e66c2befb4';
var stopOneImageUrl       = 'https://firebasestorage.googleapis.com/v0/b/grow-maps-platform.appspot.com/o/growmaps_ex_icon%2Fstop1.png?alt=media&token=31fbc3ae-67c8-419c-b1a5-a1a2a7dfa207';
var stopTwoImageUrl       = 'https://firebasestorage.googleapis.com/v0/b/grow-maps-platform.appspot.com/o/growmaps_ex_icon%2Fstop2.png?alt=media&token=b4ac652b-4598-42f6-9aad-8b3ed73268c8';
var stopThreeImageUrl     = 'https://firebasestorage.googleapis.com/v0/b/grow-maps-platform.appspot.com/o/growmaps_ex_icon%2Fstop3.png?alt=media&token=0ab9ac64-01ff-4fb8-ba53-be8510020568';
var upImageUrl            = 'https://firebasestorage.googleapis.com/v0/b/grow-maps-platform.appspot.com/o/growmaps_ex_icon%2Fup.png?alt=media&token=dd8ecdb2-f206-45aa-84cb-fff78b56b4b8';
var downImageUrl          = 'https://firebasestorage.googleapis.com/v0/b/grow-maps-platform.appspot.com/o/growmaps_ex_icon%2Fdown.png?alt=media&token=5fd72104-b2d1-4b30-9612-c213539ba8bc'; 
var wcImageUrl            = 'https://firebasestorage.googleapis.com/v0/b/grow-maps-platform.appspot.com/o/growmaps_ex_icon%2Fwc.png?alt=media&token=eb32001a-a0e5-4c3d-8d2c-4c5594ae2ee5';

// 심볼 이미지 URL
var amenitiesImageUrl       = 'https://firebasestorage.googleapis.com/v0/b/grow-maps-platform.appspot.com/o/growmaps_ex_icon%2FAmenities.png?alt=media&token=417da119-9a73-411f-aaf4-f128a5edc7fd';
var businessImageUrl        = 'https://firebasestorage.googleapis.com/v0/b/grow-maps-platform.appspot.com/o/growmaps_ex_icon%2FBusiness.png?alt=media&token=b046d921-8e0f-4547-bae0-6d1902f49dbb';
var cafeImageUrl            = 'https://firebasestorage.googleapis.com/v0/b/grow-maps-platform.appspot.com/o/growmaps_ex_icon%2FCaf%C3%A9.png?alt=media&token=cb8773fa-4401-42d9-b754-a05ee3b32d2a';
var cultureImageUrl         = 'https://firebasestorage.googleapis.com/v0/b/grow-maps-platform.appspot.com/o/growmaps_ex_icon%2FCulture.png?alt=media&token=05e858ea-41e5-4139-b071-8502a73d7626';
var fashionImageUrl         = 'https://firebasestorage.googleapis.com/v0/b/grow-maps-platform.appspot.com/o/growmaps_ex_icon%2FFashion.png?alt=media&token=f94219b6-9a8e-48c6-bde7-d2753cfdf50e';
var infrastructureImageUrl  = 'https://firebasestorage.googleapis.com/v0/b/grow-maps-platform.appspot.com/o/growmaps_ex_icon%2FInfrastructure.png?alt=media&token=702eedb7-902f-4554-b1ec-7d0ddd77c7d9';
var leisureImageUrl         = 'https://firebasestorage.googleapis.com/v0/b/grow-maps-platform.appspot.com/o/growmaps_ex_icon%2FLeisure.png?alt=media&token=e08d82f1-a95d-43c2-bb8b-fa31aed5a050';
var otherImageUrl           = 'https://firebasestorage.googleapis.com/v0/b/grow-maps-platform.appspot.com/o/growmaps_ex_icon%2FOther.png?alt=media&token=85a9cbb5-f432-407d-9379-33c89db4cca2';
var publicOfficeImageUrl    = 'https://firebasestorage.googleapis.com/v0/b/grow-maps-platform.appspot.com/o/growmaps_ex_icon%2FPublicoffice.png?alt=media&token=9b901e88-b0e3-4755-9ef1-490b2fa58267';
var restaurantImageUrl      = 'https://firebasestorage.googleapis.com/v0/b/grow-maps-platform.appspot.com/o/growmaps_ex_icon%2FRestaurant.png?alt=media&token=db5db771-e804-4099-a797-244cd3843bb7';
var shoppingImageUrl        = 'https://firebasestorage.googleapis.com/v0/b/grow-maps-platform.appspot.com/o/growmaps_ex_icon%2FShopping.png?alt=media&token=f6b4b92e-6b50-4041-bc78-d61f5743c9f3';
var transportationImageUrl  = 'https://firebasestorage.googleapis.com/v0/b/grow-maps-platform.appspot.com/o/growmaps_ex_icon%2FTransportation.png?alt=media&token=26392dfd-7a23-4b86-bd89-b0301d315348';
var restImageUrl            = 'https://firebasestorage.googleapis.com/v0/b/grow-maps-platform.appspot.com/o/growmaps_ex_icon%2Frest.png?alt=media&token=cce6f8f3-c747-435f-9ae4-450f18aa152a';
var busImageUrl             = 'https://firebasestorage.googleapis.com/v0/b/grow-maps-platform.appspot.com/o/growmaps_ex_icon%2FBus.png?alt=media&token=d0572059-7cc0-4bf0-b99d-451944fc108a';

// 영문 URL
var startENImageUrl         = 'https://firebasestorage.googleapis.com/v0/b/grow-maps-platform.appspot.com/o/growmaps_ex_icon%2FFrom_en.png?alt=media&token=09e0e6aa-97a8-433c-9787-5afe1f690908';
var endENImageUrl           = 'https://firebasestorage.googleapis.com/v0/b/grow-maps-platform.appspot.com/o/growmaps_ex_icon%2FTo_en.png?alt=media&token=4cb82d47-7306-424e-a212-b96f422272d9';
var myPositionENImageUrl    = 'https://firebasestorage.googleapis.com/v0/b/grow-maps-platform.appspot.com/o/growmaps_ex_icon%2Fhere_en.png?alt=media&token=93479f4c-5845-4b7d-916d-a650f1168a3d';
var stopOneENImageUrl       = 'https://firebasestorage.googleapis.com/v0/b/grow-maps-platform.appspot.com/o/growmaps_ex_icon%2Fstop1_en.png?alt=media&token=c5592764-1a7d-4269-834d-13be656af498';
var stopTwoENImageUrl       = 'https://firebasestorage.googleapis.com/v0/b/grow-maps-platform.appspot.com/o/growmaps_ex_icon%2Fstop2_en.png?alt=media&token=a0d030aa-fcfc-46c8-85ba-fe25d9b233c2';
var stopThreeENImageUrl     = 'https://firebasestorage.googleapis.com/v0/b/grow-maps-platform.appspot.com/o/growmaps_ex_icon%2Fstop3_en.png?alt=media&token=98fe01f8-c976-436c-89c9-87a02a9510f7';
var upENImageUrl            = 'https://firebasestorage.googleapis.com/v0/b/grow-maps-platform.appspot.com/o/growmaps_ex_icon%2Fup_en.png?alt=media&token=21edb04c-c977-4de6-a8d1-e123665bb489';
var downENImageUrl          = 'https://firebasestorage.googleapis.com/v0/b/grow-maps-platform.appspot.com/o/growmaps_ex_icon%2Fdown_en.png?alt=media&token=91b68c03-6ee5-4434-86ee-3abeadb368cf'; 

// 탑승, 하차
var getOnImageUrl     = 'https://firebasestorage.googleapis.com/v0/b/grow-maps-platform.appspot.com/o/growmaps_ex_icon%2Fget_on.png?alt=media&token=7875ab90-7a36-42bd-aa5d-f4992b3f4a1f';
var getOffImageUrl    = 'https://firebasestorage.googleapis.com/v0/b/grow-maps-platform.appspot.com/o/growmaps_ex_icon%2Fget_off.png?alt=media&token=de322424-6ca7-474f-9c2f-0e72554f88a0';
var getOnENImageUrl   = 'https://firebasestorage.googleapis.com/v0/b/grow-maps-platform.appspot.com/o/growmaps_ex_icon%2Fget_on_en.png?alt=media&token=a6d01132-4be6-4b79-ad1c-95c372f91ab5';
var getOffENImageUrl  = 'https://firebasestorage.googleapis.com/v0/b/grow-maps-platform.appspot.com/o/growmaps_ex_icon%2Fget_off_en.png?alt=media&token=d8787f46-b804-4329-85c4-bd2152f689db';

// 계단, 에스컬레이터, 엘레베이터 위로/아래로
var elevatorUpImageUrl    = 'https://firebasestorage.googleapis.com/v0/b/grow-maps-platform.appspot.com/o/growmaps_ex_icon%2Felevator_up.png?alt=media&token=673a34ac-c2ca-4035-8322-7135cc260831';
var elevatorDownImageUrl  = 'https://firebasestorage.googleapis.com/v0/b/grow-maps-platform.appspot.com/o/growmaps_ex_icon%2Felevator_down.png?alt=media&token=6bca1083-6eb8-45e1-8830-56f9377858fa';
var escalatorUpImageUrl   = 'https://firebasestorage.googleapis.com/v0/b/grow-maps-platform.appspot.com/o/growmaps_ex_icon%2Fescalator_up.png?alt=media&token=7bce3a2c-ad3a-4706-9bc2-d24ac2b4879d';
var escalatorDownImageUrl = 'https://firebasestorage.googleapis.com/v0/b/grow-maps-platform.appspot.com/o/growmaps_ex_icon%2Fescalator_down.png?alt=media&token=74be0f7e-bb30-47d5-9ae7-7f00f58c23e9';
var stairsUpImageUrl      = 'https://firebasestorage.googleapis.com/v0/b/grow-maps-platform.appspot.com/o/growmaps_ex_icon%2Fstairs_up.png?alt=media&token=d979a39c-c06d-4f8f-bc05-09ccf2b88b07';
var stairsDownImageUrl    = 'https://firebasestorage.googleapis.com/v0/b/grow-maps-platform.appspot.com/o/growmaps_ex_icon%2Fstairs_down.png?alt=media&token=c58d5098-195e-4576-8f52-867cea3e88f7'; 

var imageUrlList = new Map([
  [pinImageUrl, 'gm_Pin'],
  [pinPressedImageUrl, 'gm_Pin_pressed'],
  [boothImageUrl, 'gm_booth'],
  [specialBoothImageUrl, 'gm_booth_1'], 
  [cafeteriaImageUrl, 'gm_cafeteria'], 
  [entranceImageUrl, 'gm_entrance'],
  [conferenceImageUrl, 'gm_conference'], 
  [endImageUrl, 'gm_end'],   
  [myPositionImageUrl, 'gm_start'], 
  [myPositionENImageUrl, 'gm_start_en'],
  [startImageUrl, 'gm_start'],
  [startENImageUrl, 'gm_start_en'],
  [meetingRoomImageUrl, 'gm_meetingRoom'],
  [stopOneImageUrl, 'gm_stop1'],
  [stopTwoImageUrl, 'gm_stop2'],
  [stopThreeImageUrl, 'gm_stop3'],
  [upImageUrl, 'gm_up'],
  [downImageUrl, 'gm_down'],
  [wcImageUrl, 'gm_restroom'],
  [dotImageUrl, 'gm_dot'],
  [amenitiesImageUrl, 'gm_Amenities'],
  [businessImageUrl, 'gm_business'],
  [cafeImageUrl, 'gm_Café'],
  [cultureImageUrl, 'gm_Culture'],
  [fashionImageUrl, 'gm_Fashion'],
  [infrastructureImageUrl, 'gm_Infrastructure'],
  [leisureImageUrl, 'gm_Leisure'],
  [otherImageUrl, 'gm_Other'],
  [publicOfficeImageUrl, 'gm_Publicoffice'],
  [restaurantImageUrl, 'gm_Restaurant'],
  [shoppingImageUrl, 'gm_Shopping'],
  [transportationImageUrl, 'gm_Transportation'],
  [endENImageUrl, 'gm_end_en'],
  [stopOneENImageUrl, 'gm_stop1_en'],
  [stopTwoENImageUrl, 'gm_stop2_en'],
  [stopThreeENImageUrl, 'gm_stop3_en'],
  [upENImageUrl, 'gm_up_en'],
  [downENImageUrl, 'gm_down_en'],
  [getOnImageUrl, 'gm_get_on'],   
  [getOffImageUrl, 'gm_get_off'],  
  [getOnENImageUrl, 'gm_get_on_en'], 
  [getOffENImageUrl, 'gm_get_off_en'],
  [restImageUrl, 'gm_rest'],
  [busImageUrl, 'gm_Bus'],
  [elevatorUpImageUrl, 'gm_elevator_up'],
  [elevatorDownImageUrl, 'gm_elevator_down'],
  [escalatorUpImageUrl, 'gm_escalator_up'],
  [escalatorDownImageUrl, 'gm_escalator_down'],
  [stairsUpImageUrl, 'gm_stairs_up'],
  [stairsDownImageUrl, 'gm_stairs_down'],
]);

// ==================================================================================================

// technique based on https://jsfiddle.net/2mws8y3q/
// an array of valid line-dasharray values, specifying the lengths of the alternating dashes and gaps that form the dash pattern
const dashArraySequence = [
  [0, 4, 3],
  [0.5, 4, 2.5],
  [1, 4, 2],
  [1.5, 4, 1.5],
  [2, 4, 1],
  [2.5, 4, 0.5],
  [3, 4, 0],
  [0, 0.5, 3, 3.5],
  [0, 1, 3, 3],
  [0, 1.5, 3, 2.5],
  [0, 2, 3, 2],
  [0, 2.5, 3, 1.5],
  [0, 3, 3, 1],
  [0, 3.5, 3, 0.5]
];

// =============== 전역변수 함수연결용 ===============
let isStopAnimation;
let poiStopOverData;
let stopOverSourceData;
let stopOverLayOutData;
let registeredStartEndLayerIDs = [];
let registeredLineLayerIDs = [];
let registeredLineSourceIDs = [];
// ================================================

// ========== User Agent ==========================

// 나침반을 사용하는 OS 를 알기위해서 정의한 변수입니다.
// 현재는 사용하지 않으므로 보류합니다.
var useragt = navigator.userAgent.toLowerCase();    
const isAndroid = /android/i.test(useragt);
// const isAndroid = useragt.match(/android/i);     
const isIOS = /iphone|ipod|ipad/.test(useragt) && /applewebkit/.test(useragt);

// ================================================

// 이미지를 로드하는 함수입니다.
function loadAndAddImage() {
  var count = 0;  
  // Map 객체 순회
  for (const [key, value] of imageUrlList) {

    if( ${(kioskMode == true) ? 'true' : 'false'} ){
      if(key == startImageUrl || key == startENImageUrl){
        continue;
      }    
    } else {
      if(key == myPositionImageUrl || key == myPositionENImageUrl){
        continue;
      }
    }

    map.loadImage(
      key,
      (error, image) => {
        if (error) {
          console.log("onStyleLoaded Failed");
          onStyleLoaded("onStyleLoaded Completed!");
          throw error;
        }
        // Add the image to the map style.
        map.addImage(value, image);
        count++; 
        console.log("count "+count+" / value : " + value);
        // 모든 이미지가 로드되면 함수 종료
        if (count == (imageUrlList.size - 2)) {
          onStyleLoaded("onStyleLoaded Completed!");
        }
      }
    )
  }
}

// 맵이 로드될 때 동작입니다.
map.on('load', () => {

    if (map) {
      loadAndAddImage();      
      map.on('click', (e)=>{
      console.log('e : ' + e.lngLat);
        // layersToQuery 배열에 포함된 레이어 중에서 맵 스타일에 존재하는 레이어만 선택
        const existingLayers = layersToQuery.filter(layer => map.getLayer(layer));
        // queryRenderedFeatures 함수는 마우스 위치에 있는 Features 의 정보를 가져옵니다.
        // 지금은 e.point 를 가져왔으므로 심볼들중에 layerID 가 layersToQuery 안에 있는것들 중에 가져옵니다.
        // 만약 없으면 features 의 길이는 0 이 나옵니다. 
        const features = [];
        existingLayers.forEach(layer => {
          const layerFeatures = map.queryRenderedFeatures(e.point, { layers: [layer] });
          features.push(...layerFeatures);
        });
        
        if (features.length === 0) {
          onMapClick(e.lngLat);
        }
      });
      
      // 현재 움직임을 콜백해줍니다.
      // Timer 를 위해서 콜백을 만들어주었습니다.
      map.on('move', (e) => {
        onMove(e);
      });
            
      map.on('zoom', function() {
        var zoomLevel = map.getZoom(); // 현재 줌 레벨 가져오기
        onMapZoom(zoomLevel);
      });

    } else {
      console.error('Map object is null.');
    }
});

// ========================== Compass 함수 (현재 보류: 성엽 2024-04-03) ========================================

/// 나침반 활성화 함수
function onEnableCompass(){
  startCompassListener(handleCompassChange);
}

/// 나침반 비활성화 함수
function onDisableCompass(){
  removeListeners();
}

/// 콜백함수 Compass 값 전달
function handleCompassChange(compass) {                           
  rotateCompass(compass);                
}

/// Compass 값을 Flutter 단으로 전달하기 위한 함수.
function rotateCompass(compass) {
  console.log("Compass value : " + compass);  
  map.rotateTo(compass, { duration: 0 });
}

// 이벤트 리스너 등록 함수
function removeListeners() {
    if(isIOS){  
      console.log("remove webkitListener!");         
      window.removeEventListener("deviceorientation", webkitListener);                    
    } else {
      console.log("remove absoluteListener!");
      window.removeEventListener("deviceorientationabsolute", absoluteListener);                    
    }      
}

// iOS 기기에서 사용할 리스너
let webkitListener = function(e, callback) {
    let compass = e.webkitCompassHeading;
    if (compass != null && !isNaN(compass)) {           
        console.log("webkitListener Compass value 1:: " + compass);                             
        callback(compass);
    } else if (e.alpha != null) {        
        console.log("webkitListener Compass value 2:: " + compass);
        compass = e.alpha || 0;
        callback(compass);
    }
};

// 안드로이드 기기에서 사용할 리스너
let absoluteListener = function(e, callback) {
    if (!e.absolute || e.alpha == null || e.beta == null || e.gamma == null)
        return;          
    var compass = e.alpha || 0;    
    callback(compass);
};

// 이벤트 리스너 등록 함수
function addListeners(callback) {
    if(isIOS){
      // alert("deviceType : iOS");      
      console.log("deviceType : iOS");
      window.addEventListener("deviceorientation", function(e) {        
        webkitListener(e, callback);
      }, true);                    
    } else {
      // alert("deviceType : android");      
      console.log("deviceType : android");
      window.addEventListener("deviceorientationabsolute", function(e) {
        absoluteListener(e, callback);
      }, true);                       
    }      
}

/// 나침반 - onEnableCompass 함수의 콜백입니다.
function startCompassListener(callback) {
  // alert("startCompassListener!");
  if (!window.DeviceOrientationEvent) {
      // alert("DeviceOrientation API not available");
      console.warn("DeviceOrientation API not available");
      return;
  }
  
  // 디바이스 방향 권한 요청
  if (typeof DeviceMotionEvent !== "undefined" && typeof DeviceMotionEvent.requestPermission === 'function') {      
      window.DeviceOrientationEvent.requestPermission()
          .then(response => {
              if (response === 'granted') {
                  console.log("DeviceOrientationEvent granted!");
                  // alert('DeviceOrientationEvent granted!');
                  addListeners(callback);
              } else if (response === 'denied'){
                  // alert("권한을 얻으려면 다시 시작해주세요.");
                  console.warn("Permission for DeviceOrientationEvent not granted");
              }              
          })
          .catch(e => {
            console.error(e);
          });
    // alert('if DeviceMotionEvent!');
  } else {
      // alert('else DeviceMotionEvent!');      
      console.log("DeviceOrientationEvent default addListeners!");                    
      addListeners(callback);
  }
}

// ============================================================================================

// 지도 이미지 그리기, 3D 테스트용도 함수 입니다.
function setFloorPlanImagesTest(imageDataValues){
      if(JSON.parse(imageDataValues) == null || JSON.parse(imageDataValues) == undefined){
        console.log('imageDataValues is null or undefined!');
        return;
      }

      var imageData = JSON.parse(imageDataValues);
      
      // console.log("imageData :: " + JSON.stringify(imageData));
      
      map.addSource('floorplan', {
      'type': 'geojson',
      'data': {
        'type': 'FeatureCollection',
        'features': imageData,
        },
      });

      map.addLayer({
      'id': 'floorplan-fill',
      'type': 'fill',
      'source': 'floorplan',
      'paint': {
      'fill-color':['get','fillColor'],
      'fill-opacity':['get','fillOpacity'],      
      }
      }, normalLayerID);
  
      map.addLayer({
      'id': 'floorplan-outline',
      'type': 'line',
      'source': 'floorplan',
      'paint': {
      'line-color':['get','lineColor'],
      'line-width':['get','lineWidth'],
      'line-opacity':['get','lineOpacity'],      
      }
      }, normalLayerID);  

      map.addLayer({
        'id': 'room-extrusion',
        'type': 'fill-extrusion',
        'source': 'floorplan',
        'paint': {
            // Get the `fill-extrusion-color` from the source `color` property.
            'fill-extrusion-color': ['get', 'fillColor'],

            // Get `fill-extrusion-height` from the source `height` property.
            'fill-extrusion-height': ['get', 'extHeight'],

            // Get `fill-extrusion-base` from the source `base_height` property.
            'fill-extrusion-base': ['get', 'extBase'],

            // Make extrusions slightly opaque to see through indoor walls.
            // 'fill-extrusion-opacity': ['get', 'fillOpacity'],
        }
      }, normalLayerID);
}

/// 모든 층의 데이터 정의하기
function setFloorPlanImages(imageDataValues){

    if(JSON.parse(imageDataValues) == null || JSON.parse(imageDataValues) == undefined){
      console.log('imageDataValues is null or undefined!');
      return;
    }

    var imageData = JSON.parse(imageDataValues);

    map.addSource('floorplan', {
    'type': 'geojson',
    'data': imageData,   
    });

    map.addLayer({
      'id': 'floorplan-fill',
      'type': 'fill',
      'source': 'floorplan',
      'paint': {
      'fill-color':['get','fillColor'],
      'fill-opacity':['get','fillOpacity'],      
      }
    });

    map.addLayer({
      'id': 'floorplan-outline',
      'type': 'line',
      'source': 'floorplan',
      'paint': {
      'line-color':['get','lineColor'],
      'line-width':['get','lineWidth'],
      'line-opacity':['get','lineOpacity'],      
      }
    });  

    // map.addLayer({
    //   'id': 'room-extrusion',
    //   'type': 'fill-extrusion',
    //   'source': 'floorplan',
    //   'paint': {          
    //     'fill-extrusion-color': ['get', 'fillColor'],
    //     'fill-extrusion-height': ['get', 'extHeight'],
    //     'fill-extrusion-base': ['get', 'extBase'],          
    //     // 'fill-extrusion-opacity': ['get', 'fillOpacity'],
    //   }
    // });

    // map.addLayer({
    //   'id': 'floorplan-fill',
    //   'type': 'fill',
    //   'source': 'floorplan',
    //   'paint': {
    //   'fill-color':['get','fill'],
    //   }
    // });
    //
    // map.addLayer({
    //   'id': 'floorplan-outline',
    //   'type': 'line',
    //   'source': 'floorplan',
    //   'paint': {
    //   'line-color':['get','stroke'],
    //   'line-width':['get','strokeWidth'],
    //   }
    // });
}

// 지도 다 불러온 후 Fliter 먹여서 선택 층의 지도만 보이게 합니다.
// 제일 밑의 room-extrusion 는 3D 를 위한 속성값입니다.
function setFilterPlanImage(floorUid){
    map.setFilter("floorplan-fill", ['all', ['match', ['get', 'floorUid'], floorUid, true, false]]);
    map.setFilter("floorplan-outline", ['all', ['match', ['get', 'floorUid'], floorUid, true, false]]);    
    // map.setFilter("room-extrusion", ['all', ['match', ['get', 'floorUid'], floorUid, true, false]]);
}

// setPOIData 함수, normalLayer Symbol 을 정의하기 위한 함수 입니다.
function setPOIData(sourceData, layOutData, languageCode){

  // normalLayerID 지우기
  removePOISymbolLayer();
  
  // map 이벤트 함수 끄기.
  map.off('click', normalLayerID, onMapPoiClickEvent);
  map.off('click', candidateLayerID, onMapPoiClickEvent);
  
  setSymbolLayerData(sourceData, layOutData, languageCode);
  
  /// Click Event 를 정의합니다. ///
  map.on('click', normalLayerID, onMapPoiClickEvent);
  map.on('click', candidateLayerID, onMapPoiClickEvent); 
  
  console.log('setPOIData end!');
}

// 심볼 클릭 이벤트를 통해서 해당 심볼의 속성의 properties 의 poiUid를 DartCallback 으로 전달합니다.
function onMapPoiClickEvent(e){
  // 심볼 클릭 이벤트 처리
  onPoiClick(e.features[0].properties.poiUid);
}

// 층간이동을 위한 마커 이벤트 처리 함수, 해당마커의 nodeUid 를 전달합니다.
function onMapStartEndMarkerClickEvent(e){  
  // 경로상에 시작점과 끝점의 마커 클릭 이벤트 처리  
  if(e.features[0].properties.nodeUid !== undefined){         
    onUpDownMarkerClick(e.features[0].properties.nodeUid);
  }
}

// 한/영 정의 함수 입니다.
function setLanguage(languageCode){  
  
  // 한/영을 선택하는 순간 모든 SymbolLayer 들을 숨깁니다.
  map.getLayer(normalLayerID) && map.setLayoutProperty(normalLayerID, 'visibility','none');
  map.getLayer(startLayerID) && map.setLayoutProperty(startLayerID, 'visibility','none');
  map.getLayer(endLayerID) && map.setLayoutProperty(endLayerID, 'visibility','none');
  map.getLayer(stopOverLayerID) && map.setLayoutProperty(stopOverLayerID, 'visibility','none');
  map.getLayer(selectedPinLayerID) && map.setLayoutProperty(selectedPinLayerID, 'visibility','none');
  
  // 경로미리보기 상태일 때 한/영 전환해주기위해 사용합니다.
  registeredStartEndLayerIDs.forEach(layerId => {
    if (map.getLayer(layerId)) {
      map.setLayoutProperty(layerId,'visibility','none');
      if(languageCode == 'en'){
        var source = map.getSource(layerId);
        var data = source._data;
        var nameEN = data.features[0].properties.nameEN;
        var imageNameEN = data.features[0].properties.imageNameEN;
        map.setLayoutProperty(layerId, 'icon-image', imageNameEN);
        map.setLayoutProperty(layerId, 'text-field', nameEN);
      }
      else{
        var source = map.getSource(layerId);
        var data = source._data;
        var name = data.features[0].properties.name;
        var imageName = data.features[0].properties.imageName;
        map.setLayoutProperty(layerId, 'icon-image', imageName);
        map.setLayoutProperty(layerId, 'text-field', name);
      }
    }
  });
 
  // 일반 마커일 때 처리
  // icon-image 와 text-field 를 바꿔줘야함.
  if(map.getLayer(normalLayerID)){      
    if(languageCode == 'en'){
      map.setLayoutProperty(normalLayerID, 'text-field', ['concat', ['get','poiAreaUid'], ['get', 'nameEN']]); 
    }
    else{
      map.setLayoutProperty(normalLayerID, 'text-field', ['concat', ['get','poiAreaUid'], ['get', 'name']]);        
    }
  }  
  
  // 출발지 마커일 때 처리
  if(map.getLayer(startLayerID)){
    
    // startLayerID를 사용하여 소스를 참조합니다.
    var source = map.getSource(startLayerID);    
    // 소스의 데이터를 가져옵니다.
    var data = source._data;
    // 데이터의 properties 객체에서 name과 nameEN 속성을 가져옵니다.
    var name = data.features[0].properties.name;
    var nameEN = data.features[0].properties.nameEN;
    var imageName = data.features[0].properties.imageName;
    var imageNameEN = data.features[0].properties.imageNameEN;
    
    if(languageCode == 'en'){
      map.setLayoutProperty(startLayerID, 'icon-image', imageNameEN);
      map.setLayoutProperty(startLayerID, 'text-field', nameEN);
    }
    else{            
      map.setLayoutProperty(startLayerID, 'icon-image', imageName);
      map.setLayoutProperty(startLayerID, 'text-field', name);
    }
  }
  
  // 도착지 마커일 때 처리
  if(map.getLayer(endLayerID)){
  
    // startLayerID를 사용하여 소스를 참조합니다.
    var source = map.getSource(endLayerID);
    
    // 소스의 데이터를 가져옵니다.
    var data = source._data;
    
    // 데이터의 properties 객체에서 name과 nameEN 속성을 가져옵니다.
    var name = data.features[0].properties.name;
    var nameEN = data.features[0].properties.nameEN;
    var imageName = data.features[0].properties.imageName;
    var imageNameEN = data.features[0].properties.imageNameEN;
    
    if(languageCode == 'en'){
      map.setLayoutProperty(endLayerID, 'icon-image', imageNameEN);
      map.setLayoutProperty(endLayerID, 'text-field', nameEN); 
    }
    else{
      map.setLayoutProperty(endLayerID, 'icon-image', imageName);
      map.setLayoutProperty(endLayerID, 'text-field', name);        
    }
  }    
  
  // 경유지 마커일 때 처리
  if(map.getLayer(stopOverLayerID)){
    if(languageCode == 'en'){
      setStopOverPoint(languageCode);
    }
    else{
      setStopOverPoint(languageCode);        
    }
  }
  
  // Poi 가 선택된 상황에 한/영을 바꿔줄 때 처리
  if(map.getLayer(selectedPinLayerID)){  
    // startLayerID를 사용하여 소스를 참조합니다.
    var source = map.getSource(selectedPinLayerID);    
    // 소스의 데이터를 가져옵니다.
    var data = source._data;
    
    // 데이터의 properties 객체에서 name과 nameEN 속성을 가져옵니다.
    var name = data.features[0].properties.name;
    var nameEN = data.features[0].properties.nameEN;
    var poiAreaUid = data.features[0].properties.poiAreaUid;
    
    if(languageCode == 'en'){
      var sumText = poiAreaUid+ " " +nameEN;
      map.setLayoutProperty(selectedPinLayerID, 'text-field', sumText);
    } else {
      var sumText = poiAreaUid+ " " +name;
      map.setLayoutProperty(selectedPinLayerID, 'text-field', sumText);
    }
  }
  
  // 0.1 초 후에 숨김을 해제합니다.
  setTimeout(() => {
    map.getLayer(normalLayerID) && map.setLayoutProperty(normalLayerID, 'visibility','visible');
    map.getLayer(startLayerID) && map.setLayoutProperty(startLayerID, 'visibility','visible');
    map.getLayer(endLayerID) && map.setLayoutProperty(endLayerID, 'visibility','visible');
    map.getLayer(stopOverLayerID) && map.setLayoutProperty(stopOverLayerID, 'visibility','visible');
    map.getLayer(selectedPinLayerID) && map.setLayoutProperty(selectedPinLayerID, 'visibility','visible');
    // 경로미리보기가 있다면 그것도 해제
    registeredStartEndLayerIDs.forEach(layerId => {
      if (map.getLayer(layerId)) {
        map.setLayoutProperty(layerId,'visibility','visible');
      }
    });
  }, 100);
}

// poi 선택 함수입니다.
function setSelectedPOI(sourceData, layOutData, languageCode){
  
  removeSelectedPin();
  
  setSymbolLayerData(sourceData, layOutData, languageCode);
  
  // 핀의 애니메이션 적용
  animateSelectedPinBounce();
}

// 핀의 바운스 애니메이션 함수
function animateSelectedPinBounce() {
  var startTime = Date.now(); // 애니메이션 시작 시간
  var initialSize = initClickedMarkerSize;  // 초기 크기 설정
  var finalSize = clickedMarkerSize; // 최종 크기 (원하는 크기로 조절)  

  function easeOutElastic(t) {
    return Math.sin(-13.0 * (t + 1.0) * Math.PI / 2) * Math.pow(2.0, -10.0 * t) + 1.0;
  }

  function animate() {
    var elapsedTime = Date.now() - startTime;
    var progress = Math.min(elapsedTime / 500, 1); // 애니메이션 진행 상태 (0부터 1까지), 500은 애니메이션 지속 시간 (밀리초)

    // 바운스 애니메이션 적용
    var easedProgress = easeOutElastic(progress);
    var newSize = initialSize + (finalSize - initialSize) * easedProgress;
    if(map.getLayer(selectedPinLayerID)){
      map.setLayoutProperty(selectedPinLayerID, 'icon-size', newSize);
    }
    
    if (progress < 1) {
      // 애니메이션이 완료되지 않았다면 다음 프레임에서 계속 애니메이션을 업데이트
      requestAnimationFrame(animate);
    } else {
      // 애니메이션이 완료되면 최종 크기로 설정
      if(map.getLayer(selectedPinLayerID)){
        map.setLayoutProperty(selectedPinLayerID, 'icon-size', finalSize);
      }
    }
  }

  animate(); // 애니메이션 시작
}

// 이 함수는 제가 짠건 아닌데.. Kiosk 의 현재위치를 설정할때 사용한다는거 같은데,
// 스튜디오에서 설정해줄 수 있으므로, 현재는 사용하지 않는 것 같습니다.
function setCurrentPosOnKiosk(latitude, longitude, name) {

  removeCandidatePin();
  removeStartSymbolLayer();

  // 새로운 시작점 레이어와 소스 추가
  map.addSource(startLayerID, {
    'type': 'geojson',
    'data': {
      'type': 'Feature',
      'geometry': {
        'type': 'Point',
        'coordinates': [longitude, latitude],
      },
      'properties': {      
        'symbolSortValue' : 3,
        'name' : name
      }
    }
  });

  map.addLayer({
    'id': startLayerID,
    'type': 'symbol',
    'source': startLayerID,
    'layout': {
      'icon-image': 'gm_now',      
      'icon-size': 1,            
      'icon-offset' : [0, -10],
      'text-font': [fonts[0],fonts[1],fonts[2]],
      'text-field': ['get', 'name'],
      'text-size': 14,
      'text-offset': [0, 1],
      'text-anchor': 'top',
      'icon-allow-overlap' : true,
      'text-allow-overlap' : true,
      'symbol-sort-key': ['get', 'symbolSortValue'],
    }
  });
}



// 출발 설정
function setStartPoint(sourceData, layOutData,languageCode) {            
    removeSymbolLayer(candidateLayerID);
    removeSymbolLayer(startLayerID);    
    setSymbolLayerData(sourceData, layOutData, languageCode);
}

// 도착 설정
function setEndPoint(sourceData, layOutData, languageCode) {    
    removeSymbolLayer(candidateLayerID);
    removeSymbolLayer(endLayerID);
    setSymbolLayerData(sourceData, layOutData, languageCode);      
}

// 경유지 설정
// 만약 출발지나 도착지를 경유지로 바꾸면 덮어씌우기
function setStopOverPoint(languageCode, sourceData, layOutData){

  removeCandidatePin();
  removeStopOverSymbolLayer();
  
  // 경유지 선택중에 언어가 변경됐을때(setLanguage) 저장되어있는 poiData를 가지고 마커만 변경되어야 하므로, 처음에 전역에 저장
  if(sourceData != undefined){
    if(JSON.parse(sourceData).length == 0) { return; }  
    stopOverSourceData = sourceData;
    stopOverLayOutData = layOutData;    
  }
  
  setSymbolLayerData(stopOverSourceData, stopOverLayOutData, languageCode);
}

// CandidatePoi List 를 생성합니다. 해당 PoiData 위에 여러개의 Pin 을 생성해줍니다.
function getCandidatePOIList(sourceData, layOutData, languageCode){  
  removeCandidatePin();  
  if(JSON.parse(sourceData).length == 0) { return; }
  setSymbolLayerData(sourceData, layOutData, languageCode); 
  animateCandidatePinBounce();
}

// 핀의 바운스 애니메이션 함수
function animateCandidatePinBounce() {
  var startTime = Date.now(); // 애니메이션 시작 시간
  var initialSize = initCandidateMarkerSize;
  var finalSize = clickedCandidateMarkerSize; // 최종 크기 (원하는 크기로 조절)

  function easeOutElastic(t) {
    return Math.sin(-13.0 * (t + 1.0) * Math.PI / 2) * Math.pow(2.0, -10.0 * t) + 1.0;
  }

  function animate() {
    var elapsedTime = Date.now() - startTime;
    var progress = Math.min(elapsedTime / 500, 1); // 애니메이션 진행 상태 (0부터 1까지), 500은 애니메이션 지속 시간 (밀리초)

    // 바운스 애니메이션 적용
    var easedProgress = easeOutElastic(progress);
    var newSize = initialSize + (finalSize - initialSize) * easedProgress;
    if(map.getLayer(candidateLayerID)){
      map.setLayoutProperty(candidateLayerID, 'icon-size', newSize);
    }
    if (progress < 1) {
      // 애니메이션이 완료되지 않았다면 다음 프레임에서 계속 애니메이션을 업데이트
      requestAnimationFrame(animate);
    } else {
      // 애니메이션이 완료되면 최종 크기로 설정
      if(map.getLayer(candidateLayerID)){
        map.setLayoutProperty(candidateLayerID, 'icon-size', finalSize);
      }
    }
  }

  animate(); // 애니메이션 시작
}

// 회색라인그리기 - 카드뷰에서 사용합니다.
function setPathFinding(fullPathList, selectedFloorUid, grayLine){
  
  removeCandidatePin();
  removeAllBackgroundLineString();
  removeAllPathSymbols();
  
  var coordinates = [];

  let fullPathListDataValue = JSON.parse(fullPathList);
  let grayLineProperty = JSON.parse(grayLine);

  for (var i = 0; i < fullPathListDataValue.length; i++) {
    var innerArray = [];    
    for(var j = 0; j < fullPathListDataValue[i].length; j++){
      var node = fullPathListDataValue[i][j];
      innerArray.push([node.pos.lng, node.pos.lat])            
    }    
    coordinates.push(innerArray);
  }
  
  // 반복적으로 그려줄 함수로 빼기
  for(let index=0 ; index < fullPathListDataValue.length; index++){
    if(fullPathListDataValue[index][0].floorUid == selectedFloorUid){
      setPathFindingOfSelectedFloor(coordinates[index], grayLineProperty, index);
    }
  }

  // 처음 출발지를 중심으로 카메라 이동
  map.flyTo({
    center: coordinates[0][0],
    zoom: 18,
    speed: 0.8,
    bearing: 0 // 항상 위쪽을 향하게 함
  });
  
  console.log('setPathFinding End');
}

// 카드뷰에서 현재 선택된 층의 회색경로를 반복적으로 그려줍니다. 
function setPathFindingOfSelectedFloor(coordinates, grayLineProperty, index){
    
  // GeoJSON 데이터 객체 생성
  var backgroundLineGeoJson = {
    'type': 'FeatureCollection',
    'features': [
      {
        'type': 'Feature',
        'geometry': {
          'type': 'LineString',
          'coordinates': coordinates
        }
      }
    ]
  };
  
  // 라인 레이어와 소스 추가
  map.addSource(lineBackgroundSourceID+index, {
    'type': 'geojson',
    'data': backgroundLineGeoJson
  });
  
    // 백그라운드 라인 레이어 추가
  for (let i = 1; i <= 3; i++) {
    const layerID = 'grayLine'+i;
    const properties = grayLineProperty[layerID];
    addBackgroundLineLayer(layerID+index, properties, lineBackgroundSourceID+index);
  }
  
  console.log('newSetPathFinding End');
}

// 경로안내시 카드뷰를 그려줍니다.
function moveToPOIaddDashedAnim(index, cardViewList, stopPlaceList, startPointName, endPointName, startMarkerImageName, endMarkerImageName, zoom, bearing, languageCode) {

  let currentIndex = JSON.parse(index);
  let cardViewListDataValue = JSON.parse(cardViewList);
  let stopPlaceListDataValue = JSON.parse(stopPlaceList);
  let zoomDataValue = JSON.parse(zoom);
  let bearingDataValue = JSON.parse(bearing);

  var stopPlaceCoordinates = stopPlaceListDataValue.map(function(poi) {
    return [poi.position.lng, poi.position.lat];
  });

  // 현재 카드뷰 Symbol 과 Layer 지우기
  removeCurrentCardView();

  var coordinates = [];
  let cardViewDataValue = cardViewListDataValue[currentIndex];

  var coordinates = cardViewDataValue.nodeList.map(function(nodeDTO) {
    return [nodeDTO.pos.lng, nodeDTO.pos.lat];
  });

  // cardViewLineGeoJson 데이터 객체 생성
  var cardViewLineGeoJson = {
    'type': 'FeatureCollection',
    'features': [
      {
        'type': 'Feature',
        'geometry': {
          'type': 'LineString',
          'coordinates': coordinates
        }
      }
    ]
  };

  // 라인 레이어와 소스 추가
  map.addSource('cardViewLine', {
    'type': 'geojson',
    'data': cardViewLineGeoJson
  });

  map.addSource('cardViewLine-dashed', {
    'type': 'geojson',
    'data': cardViewLineGeoJson
  });

  // 라인 레이어 추가
  map.addLayer({
    'id': 'cardViewLine',
    'type': 'line',
    'source': 'cardViewLine',
    'paint': {
      'line-color':'#7A5AF8',
      'line-width': 12,
      'line-opacity': 1
    }
  });

  map.addLayer({
    'id': 'cardViewLine-dashed',
    'type': 'line',
    'source': 'cardViewLine-dashed',
    'layout': {},
    'paint': {
      'line-color': '#EBE9FE',
      'line-width': 6,
      'line-dasharray': [0, 4, 3]
    }
  });

  var currentStopOverPos = null;
  var currentStopOverIndex = null;
  
  // 배열 내에서 같은 좌표를 찾아 인덱스 가져오기 - 해당 인덱스는 경유지 심볼을 넣어주자.
  // coordinates 배열에 stopPlaceCoordinates 배열의 각 좌표가 있는지 확인하고, 일치하는 인덱스를 가져오기  
  for(let i=0; i < coordinates.length ; i++){
    for(let j=0; j < stopPlaceCoordinates.length ; j++){      
      if(coordinates[i][0] === stopPlaceCoordinates[j][0] &&
         coordinates[i][1] === stopPlaceCoordinates[j][1]){              
        var currentStopOverPos = coordinates[i];  // 경유지의 좌표 가져오기
        var currentStopOverIndex = j+1; // 경유지 인덱스 가져오기
      }
    }
  }
  
  // 노드상의 출발점 데이터
  var startIndexSymbolGeoJson = {
    'type': 'FeatureCollection',
    'features': [
      {
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': coordinates[0]
        },
        'properties': {
          'index' : currentIndex,
          'name' : startPointName,
          'imageName' : startMarkerImageName,          
        },
      }
    ]
  };
  // 노드상에 도착점 데이터
  var endIndexSymbolGeoJson = {
    'type': 'FeatureCollection',
    'features': [
      {
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': coordinates[coordinates.length-1]
        },
        'properties': {
          'index' : currentIndex + 1,
          'name' : endPointName,
          'imageName' : endMarkerImageName,          
        },        
      }
    ]
  };
    
  // 출발점 소스 추가
  map.addSource(startLayerID, {
    'type': 'geojson',
    'data': startIndexSymbolGeoJson,
  });
  // 도착점 소스 추가
  map.addSource(endLayerID, {
    'type': 'geojson',
    'data': endIndexSymbolGeoJson,
  });
  
  // 여기서 Index 가 0 or 마지막일경우 체크해서 심볼이미지 변경해주기
  // start 레이어 설정
  
  map.addLayer({
    'id': startLayerID,
    'type': 'symbol',
    'source': startLayerID,
    'layout': {
      'icon-image': [
      'case',
      ['==', (languageCode), 'ko'],
      ['get', 'imageName'],
      ['==', (languageCode), 'en'],
      ['get', 'imageName'],
      ['get', 'imageName'],
      ],        
      'icon-size': startPointMarkerSize,               
      'icon-offset' : [
      'case',
      ['==', ['get','imageName'], 'gm_dot'],
      [0, 0],
      [0,-60],
      ],
      'text-font': [fonts[0],fonts[1],fonts[2]],
      'text-field': ['get', 'name'],
      'text-size': 14,
      'text-offset': [0, 1],
      'text-anchor': 'top',
      'icon-allow-overlap' : true,
      'text-allow-overlap' : true,
    }
  });   
  
  map.addLayer({
    'id': endLayerID,
    'type': 'symbol',
    'source': endLayerID,
    'layout': {
      'icon-image': [
      'case',
      ['==', (languageCode), 'ko'],
      ['get', 'imageName'],
      ['==', (languageCode), 'en'],
      ['get', 'imageName'],
      ['get', 'imageName'],
      ],        
      'icon-size': endPointMarkerSize,
      // 'icon-offset' : [0, -60],      
      'icon-offset' : [
      'case',
      ['==', ['get','imageName'], 'gm_dot'],
      [0, 0],
      [0, -60],
      ],
      'text-font': [fonts[0],fonts[1],fonts[2]],
      'text-field': ['get', 'name'],
      'text-size': 14,
      'text-offset': [0, 1],
      'text-anchor': 'top',
      'icon-allow-overlap' : true,
      'text-allow-overlap' : true,
    }
  });
  
  // 경유지가 있으면 추가해줌
  if (currentStopOverIndex != null) {
    // 노드상의 경유지 데이터
    var stopOverIndexSymbolGeoJson = {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'geometry': {
            'type': 'Point',
            'coordinates': currentStopOverPos
          },
          'properties': {
            'index' : currentStopOverIndex
          },
        }
      ]
    };

    // 경유지 소스 추가
    map.addSource(stopOverLayerID, {
      'type': 'geojson',
      'data': stopOverIndexSymbolGeoJson
    });

    // Add a symbol layer
    map.addLayer({
      'id': stopOverLayerID,
      'type': 'symbol',
      'source': stopOverLayerID,
      'layout': {
        'icon-image': ['concat', 'gm_stop', ['to-string', ['get', 'index']],
        [
          'case',
          ['==', (languageCode), 'ko'],
          '',
          ['==', (languageCode), 'en'],
          '_en',
          ''
        ]
        ],
        'icon-size': stopPlaceMarkerSize,
        'icon-offset' : [0, -60],
        'icon-allow-overlap' : true,
      },      
    });    
  }
  
  // var nextPOICoordinates = coordinates[coordinates.length-1]; // 끝값
  var nextPOICoordinates = coordinates[1]; // 두번째 값
  var centerPoint = [((coordinates[0][0] + nextPOICoordinates[0])/2), ((coordinates[0][1] + nextPOICoordinates[1])/2)];
  
  map.flyTo({
    center: centerPoint,
    zoom: zoomDataValue,
    speed: 0.75,
    bearing: bearingDataValue,
    pitch: 40,
  });
    
  isStopAnimation = false;
  // timestamp 값에 따라서 newStep 을 계속 변경 - 재귀함수로 스크립트 안에서 계속 동작하는 애니메이션
  // 지우고 다시 생성할 때 재귀함수때문에 터지는 경우가 생겨서 제어문 추가
  //============================================================================================  
  if(map.getLayer('cardViewLine-dashed')){
    animateDashArray(0);
  }
  //============================================================================================  
}

/// https://docs.mapbox.com/mapbox-gl-js/example/animate-ant-path/ 참고예제 입니다.
let step = 0;
let animationId;
function animateDashArray(timestamp) {  
  const newStep = parseInt(
    (timestamp / 50) % dashArraySequence.length
  );
  
  if(map.getLayer('cardViewLine-dashed')){
    if (newStep !== step) {
    map.setPaintProperty(
      'cardViewLine-dashed',
      'line-dasharray',
      dashArraySequence[step]
    );
      step = newStep;
    }  
  }
  
  if(isStopAnimation == false){    
    animationId = requestAnimationFrame(animateDashArray);    
  }
}


// Stop the animation when needed
function stopAnimation() {  
  if (animationId !== null) {
    isStopAnimation = true;    
    cancelAnimationFrame(animationId);
    animationId = null; 
  }
}

// 경로미리보기를 그려줍니다.
function drawAllMovingPathPreview(lineSourceList, startSymbolSourceList, endSymbolSourceList, growmapsLine, symbolLayOutData, languageCode){

    removeSymbolLayer(startLayerID);
    removeSymbolLayer(endLayerID);
    removeSymbolLayer(stopOverLayerID);

    // 현재 그려져있는 모든 라인 지우기 동작
    removeAllBackgroundLineString();
    // 현재 그려져있는 모든 라인에 해당하는 출발-도착점 지우기 동작
    unregisterMarkerClickAllLayers();
    
    if(JSON.parse(lineSourceList).length == 0) return;
    
    var lineSourceValueList = JSON.parse(lineSourceList);
    var startValueList = JSON.parse(startSymbolSourceList);
    var endValueList = JSON.parse(endSymbolSourceList);
    var growmapsLineProperty = JSON.parse(growmapsLine);

    setSymbolLayerData(startSymbolSourceList, symbolLayOutData, languageCode);
    setSymbolLayerData(endSymbolSourceList, symbolLayOutData, languageCode);

    // 반복적으로 그려줄 함수로 빼기
    for(let index=0 ; index < lineSourceValueList.length; index++){
      setLineLayerData(lineSourceValueList[index], growmapsLineProperty);      
      registerMarkerClickEvent(startValueList[index].layerID);
      registerMarkerClickEvent(endValueList[index].layerID);
    }
}

// // 두 지점 간의 방향(베어링)을 계산하는 함수
// function getBearing(start, end) {
//   // 좌표 반전
//   const reversedStart = [start[1], start[0]];
//   const reversedEnd = [end[1], end[0]];
//
//   // turf.bearing 사용
//   const bearing = turf.bearing(reversedStart, reversedEnd);
//
//   return bearing;
// }

//==================== 모든 카메라, 스크린 관련 함수 ================================

// 해당 position 으로 이동시켜줍니다(jump)
function jumpToCenterPoi(position){
  var _position = JSON.parse(position);
  
  // 해당 LatLng 위치를 중심으로 카메라 이동
  map.jumpTo({
    center: [_position.lng, _position.lat],
  });  
}

// 해당 position 으로 이동시켜줍니다(fly)
function flyToCenterPoi(position, speed, zoom){
  var _position = JSON.parse(position);
  var _speed = JSON.parse(speed);
  var _zoom = JSON.parse(zoom);
  
  // 해당 LatLng 위치를 중심으로 카메라 이동
  map.flyTo({
    center: [_position.lng, _position.lat],
    speed: _speed !== null? _speed : initialSpeed,
    zoom: _zoom !== null ? _zoom : map.getZoom(),
  });
}

// 현재 위치는 그대로 두고, zoom, bearing, pitch 를 설정해줄 때 사용합니다.
function resetPitchZoomBearingAtCenter(zoom, bearing, pitch){  
  var _zoom = JSON.parse(zoom);  
  var _bearing = JSON.parse(bearing);
  var _pitch = JSON.parse(pitch);

  map.jumpTo({
    center: map.getCenter(),
    zoom: _zoom !== null ? _zoom : map.getZoom(),
    bearing: _bearing !== null ? _bearing : map.getBearing(),
    pitch: _pitch !== null ? _pitch : map.getPitch(),
  });
}

// 카메라 타입을 fly or jump 로 정의하고, camData 를 넣어줍니다.
// camData 에는 position, zoom, bearing, pitch 에 대한 정보가 들어갑니다.
function cameraMove(moveType, camData){
  var camData = JSON.parse(camData);
  if(moveType == 'jumpTo'){
    map.jumpTo(camData);
  }
  else{
    map.flyTo(camData);
  }
}

// jumpTo camera 이동시, 설정값을 세세히 주려면 사용합니다.
// 많이 사용하진 않습니다. 
function jumpToCenterPoiInDetail(position, zoom, bearing, pitch){
  
  var _position = JSON.parse(position);
  var _zoom = JSON.parse(zoom);  
  var _bearing = JSON.parse(bearing);
  var _pitch = JSON.parse(pitch);
  
  // 해당 LatLng 위치를 중심으로 카메라 이동
  map.jumpTo({
    center: [_position.lng, _position.lat],
    zoom: _zoom !== null ? _zoom : map.getZoom(),
    bearing: _bearing !== null ? _bearing : initialBearing,
    pitch: _pitch !== null ? _pitch : initialPitch,
  });
}

// flyTo camera 이동시, 설정값을 세세히 주려면 사용합니다.
// 많이 사용하진 않습니다.
function flyToCenterPoiInDetail(position, zoom, speed, bearing, pitch){
  
  var _position = JSON.parse(position);
  var _zoom = JSON.parse(zoom);
  var _speed = JSON.parse(speed);
  var _bearing = JSON.parse(bearing);
  var _pitch = JSON.parse(pitch);
  
  // 해당 LatLng 위치를 중심으로 카메라 이동
  map.flyTo({
    center: [_position.lng, _position.lat],
    zoom: _zoom !== null ? _zoom : map.getZoom(),
    speed: _speed !== null ? _speed : initialSpeed,
    bearing: _bearing !== null ? _bearing : initialBearing,
    pitch: _pitch !== null ? _pitch : initialPitch,
  });
}

// 많이 사용하진 않지만, 현재 LatLng 위치를 중심으로 jumpTo 타입으로 카메라를 이동시키고 싶을 때 사용합니다.
function jumpToCenterPitchAndBearing(zoom, bearing, pitch){
  
  var _zoom = JSON.parse(zoom);  
  var _bearing = JSON.parse(bearing);
  var _pitch = JSON.parse(pitch);
  
  // 해당 LatLng 위치를 중심으로 카메라 이동
  map.jumpTo({    
    zoom: _zoom !== null ? _zoom : map.getZoom(),    
    bearing: _bearing !== null ? _bearing : initialBearing,
    pitch: _pitch !== null ? _pitch : initialPitch,
  });
}

// 많이 사용하진 않지만, 현재 LatLng 위치를 중심으로 flyTo 타입으로 카메라를 이동시키고 싶을 때 사용합니다.
function flyToCenterPitchAndBearing(zoom, speed, bearing, pitch){
  
  var _zoom = JSON.parse(zoom);
  var _speed = JSON.parse(speed);
  var _bearing = JSON.parse(bearing);
  var _pitch = JSON.parse(pitch);
  
  // 해당 LatLng 위치를 중심으로 카메라 이동
  map.flyTo({
    zoom: _zoom !== null ? _zoom : map.getZoom(), 
    speed: _speed !== null ? _speed : initialSpeed,   
    bearing: _bearing !== null ? _bearing : initialBearing,
    pitch: _pitch !== null ? _pitch : initialPitch,
  });
}

// 현재는 사용하지 않지만,
// 경로미리보기시에 모든경로가 화면안에 보이게 하는 기능입니다.
// 파라메터로는 현재 모든 경로(fullPathList) 와 top,bottom,left,right 패딩값을 주면 
// 그려지는 경로를 한 화면에 볼 수 있습니다. 
function fitToTheBoundsOfLineString(fullPathList, top, bottom, left, right){
    
  let fullPathListDataValue = JSON.parse(fullPathList);
  
  var topValue = JSON.parse(top);
  var bottomValue = JSON.parse(bottom);
  var leftValue = JSON.parse(left);
  var rightValue = JSON.parse(right);
  
  var coordinates = [];  
  for (var i = 0; i < fullPathListDataValue.length; i++) {
    var node = fullPathListDataValue[i];
    coordinates.push([node.pos.lng, node.pos.lat]);    
  }
  
  // 출발 심볼 데이터 생성
  var firstCoordinates = [fullPathListDataValue[0].pos.lng , fullPathListDataValue[0].pos.lat];
  
  // Create a 'LngLatBounds' with both corners at the first coordinate.
  const bounds = new mapboxgl.LngLatBounds(
    new mapboxgl.LngLat(firstCoordinates[0], firstCoordinates[1]),
    new mapboxgl.LngLat(firstCoordinates[0], firstCoordinates[1])
  );
   
  // Extend the 'LngLatBounds' to include every coordinate in the bounds result.
  for (const coord of coordinates) {
    bounds.extend(coord);
  }
  
  map.fitBounds(bounds, {
    padding: {top: topValue, bottom: bottomValue, left: leftValue, right: rightValue},
  });
}

// 현재 위도,경도 얻어오는 함수. 아직 활용 안함.
function getBoundsToCurrentScreen(){
  const bounds = map.getBounds();
  console.log('bounds : ' + bounds);
  var sw = bounds.getSouthWest(); // 남서쪽 좌표 (Southwest)
  var ne = bounds.getNorthEast(); // 북동쪽 좌표 (Northeast)

  // onMapBounds(bounds.getWest(),bounds.getEast(),bounds.getNorth(),bounds.getSouth());
}

// 전달받은 위도,경도(남서쪽, 경도,위도 / 북동쪽 경도,위도)로 카메라 위치를 벗어나지 못하도록 제한하는 함수.
function setBoundsScreen(swLatLng, neLatLng){
  
  var _swLatLng = JSON.parse(swLatLng);
  var _neLatLng = JSON.parse(neLatLng);
  
  // Create a 'LngLatBounds' with both corners at the first coordinate.
  const bounds = new mapboxgl.LngLatBounds(
      [_swLatLng.lng, _swLatLng.lat], // 남서쪽 경도, 위도
      [_neLatLng.lng, _neLatLng.lat]  // 북동쪽 경도, 위도
  );
  
  // 현재 카메라의 위치를 제한합니다.
  map.setMaxBounds(bounds);
  
  console.log('setMaxBounds end!');
}

// 카메라위치 제한을 해제하는 함수입니다.
function deleteBoundsScreen(){  
  map.setMaxBounds(null);
}

// 키오스크의 카메라 고정에 쓰였던 함수 입니다.
// 지금은 사용하지 않습니다.
function fixCameraToKiosk() {
  // 마우스 우클릭 지도 이동-회전 비활성화
  map.dragRotate.disable();
  // 터치 제스쳐에서 줌과 회전을 제어. 회전을 비활성화
  map.touchZoomRotate.disableRotation();
}

//=======================================================================

//====================== 중복 그리기 관련 ==================================

// sourceData 가 여러개 layOutData 여러개 일때 처리.
// Symbol 과 관련된 SourceData와 LayOutData, languageCode 를 받아서 그려줍니다.
function setSymbolLayerData(sourceData, layOutData, languageCode){
  var sourceValue = JSON.parse(sourceData);
  var layOutDataValue = JSON.parse(layOutData);  
  
  var layerID = sourceValue[0].layerID;
  var layerType = layOutDataValue.layerType;
  var markerType = sourceValue[0].symbolMarkerType;  
  
  // console.log("layerID :: " + layerID);
  // console.log("sourceValue.length :: " + sourceValue.length);
  // console.log("sourceValue[0] :: " + JSON.stringify(sourceValue[0]));
  // console.log("sourceValue[0].latLngList :: " + JSON.stringify(sourceValue[0].latLngList));
  
  // 좌표  
  var coordinates = [];
  for(let i=0; i<sourceValue.length; i++){
    var array = [];
    for(let j=0; j<sourceValue[i].latLngList.length; j++){      
      array.push(sourceValue[i].latLngList[j].lng);
      array.push(sourceValue[i].latLngList[j].lat);
    }
    coordinates.push(array);
  }
  
  // Features
  var features = [];  
  for(let i=0; i<sourceValue.length; i++){
    var jsonData = new Object();    
    if(sourceValue[i].poiUid == ''){ continue; }
    
    jsonData = {
      'type': 'Feature',
      'geometry': {
        'type': sourceValue[i].shapeType,
        'coordinates': coordinates[i]
      },
      'properties': {
          'name': sourceValue[i].name || '',
          'nameEN': sourceValue[i].nameEN || '',
          'imageName': sourceValue[i].imageName || 'gm_booth',
          'imageNameEN': sourceValue[i].imageNameEN || 'gm_booth',
          'nodeUid': sourceValue[i].nodeUid || '',
          'poiUid': sourceValue[i].poiUid || '',
          'symbolSortValue' : (sourceValue[i].symbolSortValue)/100 || 1,           
          'poiAreaUid': sourceValue[i].poiAreaUid != undefined && initialDisplayMapNumber == true ? '('+sourceValue[i].poiAreaUid+') ' : '',
          'index' : sourceValue[i].index || 0,
          'minzoom' : sourceValue[i].minzoom,
          'maxzoom' : sourceValue[i].maxzoom,
      }
    }
    
    features.push(jsonData);
  }
  
  // console.log("features :: " + JSON.stringify(features));
  
  // 새로운 시작점 레이어와 소스 추가
  map.addSource(layerID, {
    'type': 'geojson',
    'data': {
      'type': 'FeatureCollection',
      'features': features,
    }
  });
  
  // 마커타입에 따라서 paint 를 정의합니다.
  if(markerType == 'candidatePOI' || markerType == 'endPoint' || markerType == 'startPoint' || markerType == 'stopOverPoint' || markerType == 'selectedPOI'){
    var paint = {
      'text-color': '#000000',
      'text-halo-color': 'rgba(255, 255, 255, 1)', // 헤일로의 색상을 지정합니다.
      'text-halo-width': 2,
      'text-halo-blur': 0 // 0에 가까운 값이 선명함          
    };
  }
  if(markerType == 'points'){
    var paint = {
      'text-color': '#344054',
      'text-halo-color': 'rgba(255, 255, 255, 1)', // 헤일로의 색상을 지정합니다.
      'text-halo-width': 2,
      'text-halo-blur': 0 // 0에 가까운 값이 선명함    
    }
  }
  
  // console.log("layerType :: " + layerType);
  // console.log("iconsize :: " + layOutDataValue['icon-size']);
  // console.log("offset :: " + layOutDataValue['icon-offset']);
  // console.log("font :: " + layOutDataValue['text-font']);
  // console.log("textsize :: " + layOutDataValue['text-size']);
  // console.log("textoffset :: " + layOutDataValue['text-offset']);
  // console.log("anchor :: " + layOutDataValue['text-anchor']);  
  // console.log("icon :: " + layOutDataValue['icon-allow-overlap']);
  // console.log("text :: " + layOutDataValue['text-allow-overlap']);
  // console.log("symbolSortValue :: " + sourceValue[0]['symbolSortValue']);
  
  map.addLayer({
      'id': layerID,
      'type': layerType,
      'source': layerID,
      'layout': {      
        'icon-size': layOutDataValue['icon-size'],
        'icon-offset' : layOutDataValue['icon-offset'] || [0,0],
        'text-font': layOutDataValue['text-font'],
        'text-field': 
        [
          'case',
          ["==", (languageCode), "ko"],
          ['concat', ['get','poiAreaUid'], ['get', 'name']],
          ["==", (languageCode), "en"],
          ['concat', ['get','poiAreaUid'], ['get', 'nameEN']],        
          ['concat', ['get','poiAreaUid'], ['get', 'name']]
        ],
        'icon-image':
        [
          'case',
          ['==', (languageCode), 'ko'], // languageCode가 'ko'일 때
          ['get', 'imageName'],
          ['==', (languageCode), 'en'], // languageCode가 'en'일 때
          ['get', 'imageNameEN'],
          ['get', 'imageName']
        ],
        'text-size': layOutDataValue['text-size'],
        'text-offset': layOutDataValue['text-offset'],
        'text-anchor': layOutDataValue['text-anchor'],
        'icon-allow-overlap' : layOutDataValue['icon-allow-overlap'],
        'text-allow-overlap' : layOutDataValue['text-allow-overlap'],                
        'symbol-sort-key': ['get', 'symbolSortValue'],
        'symbol-z-order' : 'source',
      },
      'paint': paint || {},
      'filter': ['all',
        ['>=', ['get', 'maxzoom'], ["zoom"]],
        ['<=', ['get', 'minzoom'], ["zoom"]],
      ]
    });  
}

// LineString 와 관련된 SourceData 와 growmapsLineProperty 를 받아서 그려줍니다.
function setLineLayerData(sourceData, growmapsLineProperty){
       
    const latLngList = sourceData.latLngList.map(item => [item]);    
    var editLayerID = sourceData.layerID + sourceData.index;    
    
    // 좌표  
    var coordinates = [];
    for(let i=0; i<latLngList.length; i++){
      var array = [];            
      for(let j=0; j<latLngList[i].length; j++){
        array.push(latLngList[i][j].lng);
        array.push(latLngList[i][j].lat);
      }
      coordinates.push(array);
    }
    // console.log("coordinates :: " + JSON.stringify(coordinates));

    // GeoJSON 데이터 객체 생성
    var backgroundLineGeoJson = {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'geometry': {
            'type': 'LineString',
            'coordinates': coordinates
          }
        }
      ]
    };
        
    // 라인 레이어와 소스 추가
    map.addSource(editLayerID, {
      'type': 'geojson',
      'data': backgroundLineGeoJson
    });
    
    // 백그라운드 라인 레이어 추가, growmapsLine1, growmapsLine2, growmapsLine3 을 정의합니다.
    // 나중에 색상이나 디테일이 바뀌어서 갯수가 달라지면 수정되어야할 코드입니다.
    for (let i = 1; i <= 3; i++) {
      const layerID = 'growmapsLine'+i;
      const properties = growmapsLineProperty[layerID];
      addBackgroundLineLayer(layerID+sourceData.index, properties, editLayerID);
    }    
}

// LineString 을 그리기위한 반복문 굴려주는 함수입니다.
function addBackgroundLineLayer(layerID, properties, lineBackgroundSourceID) {     
  map.addLayer({
    'id': layerID,
    'type': 'line',
    'source': lineBackgroundSourceID,
    'layout': {
      'line-join': properties["line-join"] || 0,
      'line-cap': properties["line-cap"] || 0,
    },
    'paint': {
      'line-color': properties["line-color"] || 0,
      'line-gap-width': properties["line-gap-width"] || 0,
      'line-width': properties["line-width"] || 0,
    }
  }, normalLayerID);
  
  registerLineLayer(layerID);
  registerLineSource(lineBackgroundSourceID);  
}

//=======================================================================

//==================== 경로미리보기 Event Listener 관련 함수 ================

// Marker Layer ID가 이미 존재하는지 여부를 확인하는 함수
// registeredStartEndLayerIDs Array 에
// 해당 layerID 가 있으면 true, 없으면 false 를 전달해줍니다.
function isLayerRegistered(layerId) {
  return registeredStartEndLayerIDs.includes(layerId);
}

// Marker Layer ID를 등록하는 함수
// registeredStartEndLayerIDs 는 Array 타입으로 경로미리보기때 그려질 시작점들과 끝점들의 layerID 들을 넣어둡니다.
// 이 layerID 들은 MapboxConstants 에서 Source 를 설정해줄 때 넣어줍니다.
function registerLayer(layerId) {
  if (!isLayerRegistered(layerId)) {
    registeredStartEndLayerIDs.push(layerId);
  }
}

// 등록된 모든 Marker Layer ID를 제거하는 함수
// registeredStartEndLayerIDs 에 등록된 layerID 에 해당하는 Layer와 Source , 그리고 clickEvent 를 제거하는 함수입니다.
function unregisterMarkerClickAllLayers() {  
  registeredStartEndLayerIDs.forEach(layerId => {
    if (map.getLayer(layerId)) {
      map.off('click', layerId, onMapStartEndMarkerClickEvent);
      map.removeLayer(layerId);
      map.removeSource(layerId);
    }
  });
  registeredStartEndLayerIDs.length = 0; // 배열 비우기
}

// Layer ID를 등록하고 마커클릭 이벤트를 등록하는 함수
function registerMarkerClickEvent(layerId) {
  if (!isLayerRegistered(layerId)) {
    map.on('click', layerId, onMapStartEndMarkerClickEvent);
    registerLayer(layerId);
  }
}

//========================================================================


//==================== 등록 관련 함수 ======================================

// LineLayer ID를 등록하는 함수
// 층마다 LineString 의 layerID 가 다르고, 같은층에서도 LineString 의 layerID 도 다르므로,
// Array 에 layerID 를 넣어둡니다. 
function registerLineLayer(layerId) {  
  if (!registeredLineLayerIDs.includes(layerId)) {
    registeredLineLayerIDs.push(layerId);
  }
}

// LineSource ID를 등록하는 함수
// 같은형식으로 registeredLineSourceIDs 에 SourceID 를 넣어둡니다.
function registerLineSource(sourceId) {  
  if (!registeredLineSourceIDs.includes(sourceId)) {
    registeredLineSourceIDs.push(sourceId);
  }
}

//========================================================================

//==================== 모든 지우기 관련 함수 ================================

// registeredLineLayerIDs 에 등록된 모든 레이어 ID를 제거하는 함수
function unregisterAllLineLayers() {  
  registeredLineLayerIDs.forEach(layerId => {
    if (map.getLayer(layerId)) {
      map.removeLayer(layerId);
    }
  });
  registeredLineLayerIDs.length = 0; // 배열 비우기
}

// registeredLineSourceIDs 에 등록된 모든 소스 ID를 제거하는 함수
function unregisterAllLineSources() {  
  registeredLineSourceIDs.forEach(sourceId => {
    if (map.getSource(sourceId)) {
      map.removeSource(sourceId);
    }
  });
  registeredLineSourceIDs.length = 0; // 배열 비우기
}

// candidateLayerID 에 해당하는 Pin 들을 제거하는 함수입니다.
function removeCandidatePin(){
  if(map.getLayer(candidateLayerID)){
    map.removeLayer(candidateLayerID);
    map.removeSource(candidateLayerID);
  }
}

// selectedPinLayerID 에 해당하는 Pin 하나를 제거하는 함수입니다.
function removeSelectedPin(){
  if(map.getLayer(selectedPinLayerID)){
    map.removeLayer(selectedPinLayerID);
    map.removeSource(selectedPinLayerID);
  }
}

// normalLayerID(일반심볼)을 모두 지웁니다. 
function removePOISymbolLayer(){
  if(map.getLayer(normalLayerID)){
    map.removeLayer(normalLayerID);
    map.removeSource(normalLayerID);
  }
}

// 출발점을 지웁니다.
function removeStartSymbolLayer(){
  // 기존 시작점 레이어가 있다면 제거
  if (map.getLayer(startLayerID)) {
    map.removeLayer(startLayerID);
    map.removeSource(startLayerID);
  }
}

// 도착점을 지웁니다.
function removeEndSymbolLayer(){
  // 기존 시작점 레이어가 있다면 제거
  if (map.getLayer(endLayerID)) {
    map.removeLayer(endLayerID);
    map.removeSource(endLayerID);
  }
}

// 경유지를 모두 지웁니다.
function removeStopOverSymbolLayer(){
  // 기존 경유지 레이어가 있다면 제거
  if (map.getLayer(stopOverLayerID)) {    
    map.removeLayer(stopOverLayerID);
    map.removeSource(stopOverLayerID);
  }
}

// layerID 에 해당하는 Symbol 을 지웁니다. 
function removeSymbolLayer(layerID){  
  (layerID == startLayerID) ? removeStartSymbolLayer() :
  (layerID == endLayerID) ? removeEndSymbolLayer() :  
  (layerID == stopOverLayerID) ? removeStopOverSymbolLayer() :
  (layerID == normalLayerID) ? removePOISymbolLayer() :
  (layerID == selectedPinLayerID) ? removeSelectedPin() :
  (layerID == candidateLayerID) ? removeCandidatePin() :
  null;
}

// 모든 등록된 LineString을 지웁니다.
function removeAllBackgroundLineString() {    
  unregisterAllLineLayers();
  unregisterAllLineSources();
  console.log('remove all lineString!');
}

// 경로미리보기에서 등록된 Symbols 들과 경유지들을 지웁니다.
function removeAllPathSymbols(){
  unregisterMarkerClickAllLayers();
  removeStopOverSymbolLayer();
  console.log('remove all symbol!');
}

// 현재 카드뷰를 정의하는 Layer 와 Source 를 지웁니다.
function removeCurrentCardView(){
  if(map.getLayer('cardViewLine1')){
    map.removeLayer('cardViewLine1');
    map.removeLayer('cardViewLine2');
    map.removeLayer('cardViewLine3');
    map.removeSource('cardViewLine');
  }
  if(map.getLayer('cardViewLine')){
    map.removeLayer('cardViewLine');
    map.removeLayer('cardViewLine-dashed');
    map.removeSource('cardViewLine');
    map.removeSource('cardViewLine-dashed');
  }
  removeStartSymbolLayer();
  removeEndSymbolLayer();
  removeStopOverSymbolLayer();
  console.log('removeCurrentCardView all!');
}

// 경로안내와 경로미리보기가 종료됐을 때 부르는 함수입니다.
// 현재 경로와 심볼들을 모두 지웁니다. 
function removeAllPathGuideSymbolAndLineString(){
  console.log('removeAllPathGuideSymbolAndLineString');
  stopAnimation();
  removeAllPathSymbols();
  removeAllBackgroundLineString();  
  removeCurrentCardView();
}

// 맵을 다시 그려줍니다.
// 맵이 깨지는 문제를 해결해줍니다. 
function mapResize(){
  map.resize();
}

//==================================================================

</script>
 
</body>
</html>  
''';
  }
}
