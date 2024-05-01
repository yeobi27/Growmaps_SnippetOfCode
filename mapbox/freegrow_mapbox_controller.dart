import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:math';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:freegrow_backend/freegrow_backend.dart';
import 'package:freegrow_frontend/freegrow_frontend.dart';
import 'package:get/get.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:growmaps_official/view/mapbox/utils/mapbox_constants.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:turf/helpers.dart';
import 'package:turf/line_segment.dart';
import 'package:turf/polygon_to_line.dart';
import 'package:webviewx/webviewx.dart';
import 'package:geolocator/geolocator.dart';
import '../../utils/responsive.dart';
import 'freegrow_mapbox_js.dart';
import 'model/source_dto.dart';

var grayLine = {
  "grayLine1": MapboxConstants.grayLines1Property().toJson(),
  "grayLine2": MapboxConstants.grayLines2Property().toJson(),
  "grayLine3": MapboxConstants.grayLines3Property().toJson(),
};
var growmapsLine = {
  "growmapsLine1": MapboxConstants.growmapsLine1Property().toJson(),
  "growmapsLine2": MapboxConstants.growmapsLine2Property().toJson(),
  "growmapsLine3": MapboxConstants.growmapsLine3Property().toJson(),
};

class FreeGrowMapController {
  Rxn<BuildingDTO> buildingDTO;
  Rxn<FloorPlanDTO> selectedFloor;
  Rxn<POIDTO> selectedPOI;
  RxList<POIDTO> candidatePOI;
  Rxn<LatLngDTO> startPoint;
  Rxn<LatLngDTO> endPoint;
  RxList<POIDTO> stopPlaceList;
  Rxn<MovingPathDTO> movingPathDTO;
  WebViewXController? webViewXController; /// webViewXController 는 주로 JS 에 메소드를 부르는 역할을 합니다.
  BuildContext? context;                  /// setMarkerLanguage, getUserLanguage, Responsive().check(context) 에서 사용하기 위해서 선언합니다.

  bool onMapboxLoaded = false;            /// 맵이 로드 되는순간을 확인하기위한 변수

  bool kioskMode = false;                 /// kiosk 일때 상태 체크를 위한 변수
  bool isPathFindingMode = false;         /// 경로안내(카드뷰)일때를 체크 하기위한 변수
  int currentCardViewIndex = 0;           /// 현재 카드뷰 인덱스를 상태를 체크하기위한 변수

  StreamSubscription? streamSelectedFloor;
  StreamSubscription? streamSelectedPOI;
  StreamSubscription? streamCandidatePOI;
  StreamSubscription? streamStartPoint;
  StreamSubscription? streamEndPoint;
  StreamSubscription? streamStopPoint;
  StreamSubscription? streamMovingPathDTO;

  FreeGrowMapController({
    required this.buildingDTO,
    required this.selectedFloor,
    required this.selectedPOI,
    required this.candidatePOI,
    required this.startPoint,
    required this.endPoint,
    required this.stopPlaceList,
    required this.movingPathDTO,
  }) {
    /// SelectedFloor가 변화되면, 지도 및 POI 다시 그리기 ///
    streamSelectedFloor?.cancel();
    streamSelectedFloor = selectedFloor.listen((p0) {
      updateMapData(whenInit: false);
    });
    /// selectedPOI 가 변화되면, Poi를 선택한 Pin을 지우거나, 생성합니다. ///
    streamSelectedPOI?.cancel();
    streamSelectedPOI = selectedPOI.listen((p0) {
      updateSelectedPOI(p0);
    });
    /// candidatePOI 가 변화되면, RxList<POIDTO> 타입으로 선택된 candidatePOI 리스트를 지우거나 생성합니다.(QuickButton에서 선택되는 리스트 처리) ///
    streamCandidatePOI?.cancel();
    streamCandidatePOI = candidatePOI.listen((p0) {
      updateCandidatePOI(p0);
    });
    /// startPoint 가 변화되면, 출발을 그리거나 지웁니다. ///
    streamStartPoint?.cancel();
    streamStartPoint = startPoint.listen((p0) {
      updateStartPoint(p0);
    });
    /// startPoint 가 변화되면, 도착을 그리거나 지웁니다. ///
    streamEndPoint?.cancel();
    streamEndPoint = endPoint.listen((p0) {
      updateEndPoint(p0);
    });
    /// stopPlaceList 가 변화되면, 경유지를 그리거나 지웁니다. ///
    streamStopPoint?.cancel();
    streamStopPoint = stopPlaceList.listen((p0) {
      updateStopPlaceList(p0);
    });
    /// movingPathDTO 가 변화되면, 미리보기/카드뷰의 총경로를 그리거나 지웁니다. ///
    streamMovingPathDTO?.cancel();
    streamMovingPathDTO = movingPathDTO.listen((p0) {
      updateMovingPathDTO(p0);
    });
  }

  /// 모든 Rxn 를 구독하고있는 StreamSubscription 의 구독을 취소합니다. ///
  void screenClose() {
    streamSelectedFloor?.cancel();
    streamSelectedPOI?.cancel();
    streamCandidatePOI?.cancel();
    streamStartPoint?.cancel();
    streamEndPoint?.cancel();
    streamStopPoint?.cancel();
    streamMovingPathDTO?.cancel();
  }

  /// 선택된 POIDTO 를 보여주는 Pin 을 생성하거나 지우는 함수 입니다. ///
  void updateSelectedPOI(POIDTO? p0) {
    if (p0 == null) {
      webViewXController?.callJsMethod('removeSelectedPin', []);
    } else {
      setSelectedPOI(p0);
    }
  }

  /// CandidatePOI 를 업데이트(여러개의 Pin 을 생성) 합니다.
  void updateCandidatePOI(List<POIDTO> p0) {
    getCandidatePOIList(p0);
  }

  /// 현재 선택된 Poi 에 Pin 을 생성합니다.
  void setSelectedPOI(POIDTO? poiDTO){
    SourceDTO sourceDTO = MapboxConstants.getSelectedPOISource(poiDTO);
    SymbolLayOutDTO symbolLayOutDTO = MapboxConstants.getSelectedPOILayer();
    webViewXController?.callJsMethod('setSelectedPOI', [jsonEncode([sourceDTO]), jsonEncode(symbolLayOutDTO), getUserLanguageCode()]);
  }

  /// 출발지 마커 이미지를 생성/삭제 합니다.  ///
  void updateStartPoint(LatLngDTO? p0) {
    if (p0 != null) {
      if (p0.floorUid == selectedFloor.value?.floorUid) {
        setStartPoint(p0);
      } else {
        webViewXController?.callJsMethod('removeStartSymbolLayer', []);   // 같은층이 아닌 경우 지워줌
      }
    }
    else{
      webViewXController?.callJsMethod('removeStartSymbolLayer', []);   // 출발지 설정이 해제되는 경우 지워줌
    }

    checkDrawMovingPath();
  }

  /// 도착지 마커 이미지를 생성/삭제 합니다.
  void updateEndPoint(LatLngDTO? p0) {
    if (p0 != null) {
      if (p0.floorUid == selectedFloor.value?.floorUid) {
        setEndPoint(p0);
      } else {
        webViewXController?.callJsMethod('removeEndSymbolLayer', []);   // 같은층이 아닌 경우 도착지를 지워줌
      }
    }
    else{
      webViewXController?.callJsMethod('removeEndSymbolLayer', []);   // 도착지 설정이 해제되는 경우 지워줌
    }
    checkDrawMovingPath();
  }

  /// 경유지리스트를 생성/삭제 합니다.
  void updateStopPlaceList(List<POIDTO> p0) {
    // 깊은복사를해서 리스트안에 POIDTO 객체 마저도 참조하지않도록 새로운 인스턴스로 생성해준다.
    List<POIDTO> copiedStopPlaceList = poiDeepCopy(p0);
    if (copiedStopPlaceList.isNotEmpty) {
      // 리스트안에 각각의 POIDTO값을 체크
      // 같은 층이면 그대로, 아니면 poiUid 비우기 - mapbox JS 단에서 처리
      for (int i = 0; i < copiedStopPlaceList.length; i++) {
        if (copiedStopPlaceList[i].floorUid != selectedFloor.value?.floorUid) {
          copiedStopPlaceList[i].poiUid = '';
        }
      }
    }
    setStopOverPoint(copiedStopPlaceList);  // 경유지 list가 emtpy일때도 set한번더 함으로써, 경유지 끄는 기능을 적용함
    checkDrawMovingPath();
  }

  /// 경로미리보기, 경로안내를 위한 경로정보인 MovingPathDTO 를 생성/삭제 합니다.
  void updateMovingPathDTO(MovingPathDTO? p0) {
    checkDrawMovingPath();
  }

  /// 출발, 도착 설정이 완료되면 갈수있는 경로를 자동으로 그림. 만약 경유지가있다면, 경유지를 추가하여 그림 ///
  Future<void> checkDrawMovingPath() async {
    if ((startPoint.value != null) &&
        (endPoint.value != null) &&
        (startPoint.value?.floorUid != null) &&
        (endPoint.value?.floorUid != null) &&
        (movingPathDTO.value != null) &&
        (isPathFindingMode == false)) {

      if (movingPathDTO.value?.fullPathList != null) {

        List<String> startMarkerNodeUids = [];
        List<String> endMarkerNodeUids = [];
        List<String> startPointNames = [];
        List<String> endPointNames = [];
        List<String> startPointNamesEN = [];
        List<String> endPointNamesEN = [];

        // 단층일때 [[ nodeList ]]
        // 다층일때 [[ nodeList ], [ nodeList ], ... [ nodeList ]]
        // 이미지이름은 예시로 단층일때, [[ 출발, 도착 ]]
        // 이미지이름은 예시로 다층일때, [[출발, 위로or아래로],[ 위or아래, 위or아래 ],..., [위or아래, 도착]] 의 패턴으로 정의하는 함수
        final (starMarkerImageNames, endMarkerImageNames, startMarkerImageNamesEN, endMarkerImageNamesEN, nodeBlockList) = getPathListOfSelectedFloor(movingPathDTO.value!);

        if (nodeBlockList!.isNotEmpty) {

          for(int i=0; i<nodeBlockList.length;i++){
            // 첫마커의 노드들과 마지막 마커의 노드들을 모아두는 작업
            startMarkerNodeUids.add(nodeBlockList[i].first.nodeUid);
            endMarkerNodeUids.add(nodeBlockList[i].last.nodeUid);

            // 해당 층의 i번째 경로에서 첫번째 노드, 즉 그어진경로의 시작점 이름을 NodeDTO 를 통해서 가져옵니다.
            // 이를 리스트로 저장합니다.
            final (startPointName, startPointNameEN) = getNameFromNodeDTO(nodeDTO: nodeBlockList[i].first);
            startPointNames.add(startPointName);
            startPointNamesEN.add(startPointNameEN);
            // 해당 층의 i번째 경로에서 마지막 노드, 즉 그어진경로의 끝점 이름을 NodeDTO 를 통해서 가져옵니다.
            // 이를 리스트로 저장합니다.
            final (endPointName, endPointNameEN) = getNameFromNodeDTO(nodeDTO: nodeBlockList[i].last);
            endPointNames.add(endPointName);
            endPointNamesEN.add(endPointNameEN);
          }
        }

        // 위에서 수집한 모든 데이터를 SourceList 로 가공해서, LineSource 와 Start,End Symbol Source 로 가져옵니다.
        final (lineSourceList, startSymbolSourceList, endSymbolSourceList) = MapboxConstants.getMovingPathSourceList(
            nodeBlockList,
            startPointNames,
            startPointNamesEN,
            starMarkerImageNames,
            startMarkerImageNamesEN,
            startMarkerNodeUids,
            endPointNames,
            endPointNamesEN,
            endMarkerImageNames,
            endMarkerImageNamesEN,
            endMarkerNodeUids,
            selectedFloor.value?.floorUid);

        /// symbolLayOutList 생성 - start 와 end 의 layout 이 속성값이 같게해줘서 한번에 설정해줬습니다.
        SymbolLayOutDTO symbolLayOutDTO = MapboxConstants.getSymbolsLayerInMovingPath();

        await webViewXController?.callJsMethod('drawAllMovingPathPreview', [
          jsonEncode(lineSourceList),
          jsonEncode(startSymbolSourceList),
          jsonEncode(endSymbolSourceList),
          jsonEncode(growmapsLine),
          jsonEncode(symbolLayOutDTO),
          getUserLanguageCode()
        ]);

        // 경로를 다 그리고 나서 경유지를 위치시킵니다.
        setStopOverPoint(stopPlaceList.value.where((element) => element.floorUid == selectedFloor.value?.floorUid).toList());
      }
    } else {
      // 경로안내가 끝나면 모든 라인을 지웁니다.
      if (isPathFindingMode == false) {
        webViewXController?.callJsMethod('removeAllBackgroundLineString', []);
      }
    }
  }

  /// 층간 이동 중 해당 층만 길이 보여야하므로, 해당 층에만 보이는 NodeList 로 나눠놓는 함수입니다.
  /// 단층일 때 [[ nodeList ]]
  /// 다층일 때 [[ nodeList ], [ nodeList ], ... [ nodeList ]]
  /// 이미지 이름을 예시로 단층일 때, [[ 출발, 도착 ]]
  /// 이미지 이름을 예시로 다층일 때, [[출발, 위로or아래로],[ 위or아래, 위or아래 ],..., [위or아래, 도착]] 의 패턴으로 나눠주는 함수
  (List<String>, List<String>, List<String>, List<String>, List<List<NodeDTO>>?) getPathListOfSelectedFloor(MovingPathDTO movingPathDTO) {
    List<NodeDTO> pathListForCopy = [];
    List<String> startMarkerImageNames = [];
    List<String> endMarkerImageNames = [];
    List<String> startMarkerImageNamesEN = [];
    List<String> endMarkerImageNamesEN = [];

    // 전체경로 완전 복사
    pathListForCopy = nodeListDeepCopy(movingPathDTO.fullPathList);

    final List<NodeDTO> copiedList = [];
    final List<List<NodeDTO>> nodeBlockList = [];
    for (int i = 1; i < pathListForCopy.length; i++) {
      final currentNode = pathListForCopy[i - 1];
      final nextNode = pathListForCopy[i];
      // transferUid 이 null 인 경우는 poi or normal 의 경우
      // nodeBlockList 에 층별로 블럭화 시켜서 List<List<NodeDTO>> 로 저장
      if (currentNode.nodeType == NodeAndEdgeType.stair && nextNode.nodeType == NodeAndEdgeType.stair ||
          currentNode.nodeType == NodeAndEdgeType.elevator && nextNode.nodeType == NodeAndEdgeType.elevator ||
          currentNode.nodeType == NodeAndEdgeType.escalator && nextNode.nodeType == NodeAndEdgeType.escalator) {
        copiedList.add(currentNode);
        nodeBlockList.add([...copiedList]);
        copiedList.clear();
      } else {
        /// 층간 uid가 아닌 경우 저장
        copiedList.add(currentNode);
      }
      /// 끝부분의 경우 저장
      if (i == pathListForCopy.length - 1 && copiedList.isNotEmpty) {
        copiedList.add(nextNode);
        nodeBlockList.add([...copiedList]);
        copiedList.clear();
      }
    }

    // 층 가져오기
    Map<int, String> floorList = ValueStateController.instance.getFloorPlanUidList();
    for(int i=0; i<nodeBlockList.length ; i++){
      /// 해당 층에 해당하는 List의 첫번째 노드의 uid 는 층간이동 수단이 반드시 포함되어있으므로,
      /// contains(":") 로 구분
      if(nodeBlockList[i].first.nodeUid.contains(':')){
        // nodeBlockList : [ [nodeList] [nodeList] [nodeList] ... [nodeList] ]
        // nodeList 안에 NodeDTO의 nodeUid 에는 규칙이 있는데 층간 이동수단 nodeUid 에는 ":" 으로 nodeUid:out_ST_1 같은 형태로
        // 값이 연결되서 들어옵니다. 그래서 nodeBlockList 안에 나눠놓은 nodeList의 첫번째 노드(first.nodeUid)의 nodeUid 와
        // 이전 nodeUid를 비교하여 위/아래층을 구분합니다.
        String arrivalFloorUid = nodeBlockList[i-1].last.floorUid;  // 층간이동 노드가 있는 nodeList의 이전 노드리스트의 끝 노드의 floorUid
        String currentFloorUid = nodeBlockList[i].first.floorUid;   // 층간이동 노드가 있는 nodeList의 현재 노드리스트의 첫 노드의 floorUid
        int arrivalFloorValue = findKeyByValue(arrivalFloorUid, floorList); // 도착층의 값을 가져옵니다.
        int currentFloorValue = findKeyByValue(currentFloorUid, floorList); // 현재층의 값을 가져옵니다.

        // fixme 하드코딩되어있음.
        // fixme 나중에 필요시에 수정해야할 사항입니다. 2024-04-19 성엽
        // 출발 노드는 항상 "하차"
        if(nodeBlockList[i].first.nodeUid.split(":")[0] == "out_ST_1"){
          startMarkerImageNames.add("gm_get_off");
          startMarkerImageNamesEN.add("gm_get_off_en");
        } else {
          /// out_ST_1 , 2_ESC_2_2, ... 이런형태로 호영님이 값을 전달해주므로, split("_")[1] 으로 정의해서 전달해줬습니다.
          final (startMarkerImageName, startMarkerImageNameEN) = getMarkerPreviewImageName(currentFloorValue, arrivalFloorValue, nodeBlockList[i].first.nodeUid.split(":")[0].split("_")[1]);
          startMarkerImageNames.add(startMarkerImageName);
          startMarkerImageNamesEN.add(startMarkerImageNameEN);
        }
      }else{
        // 둘다 아닐경우 출발 이미지 이름 추가
        startMarkerImageNames.add("gm_start");
        startMarkerImageNamesEN.add("gm_start_en");
      }
      if(nodeBlockList[i].last.nodeUid.contains(':')){
        // 위의 설명과 마찬가지로 끝노드의 nodeUid 와 다음 노드리스트의 첫번째노드의 nodeUid 를 비교해
        // 위/아래 층을 구분합니다.
        String currentFloorUid = nodeBlockList[i].last.floorUid;
        String arrivalFloorUid = nodeBlockList[i+1].first.floorUid;
        int arrivalFloorValue = findKeyByValue(arrivalFloorUid, floorList);
        int currentFloorValue = findKeyByValue(currentFloorUid, floorList);

        // fixme 나중에 수정해야할 사항입니다. 2024-04-19 성엽
        // fixme 현재 탑승,하차를 하드코딩으로 넣고,
        // fixme 엘레베이터, 에스컬레이터, 계단은 ST, EV, ESC 로 구분하여 넣어줬습니다.
        // 도착 노드는 항상 "탑승"
        if(nodeBlockList[i+1].first.nodeUid.split(":")[0] == "out_ST_1"){
          endMarkerImageNames.add("gm_get_on");
          endMarkerImageNamesEN.add("gm_get_on_en");
        } else {
          final (endMarkerImageName, endMarkerImageNameEN) = getMarkerPreviewImageName(currentFloorValue, arrivalFloorValue, nodeBlockList[i].last.nodeUid.split(":")[0].split("_")[1]);
          endMarkerImageNames.add(endMarkerImageName);
          endMarkerImageNamesEN.add(endMarkerImageNameEN);
        }
      }else{
        endMarkerImageNames.add("gm_end");
        endMarkerImageNamesEN.add("gm_end_en");
      }
    }
    return (startMarkerImageNames, endMarkerImageNames, startMarkerImageNamesEN, endMarkerImageNamesEN, nodeBlockList);
  }

  /// 층간이동수단의 마커이미지를 정의하기위한 함수.
  /// out_ST_1 , 2_ESC_2_2, ... 이런형태로 호영님이 값을 전달해주므로, split("_")[1] 으로 정의해서 전달해줬습니다.
  /// 만약 형태가 변경이되더라도 ST, ESC, EV 를 잘 전달해주시기만 하면 됩니다.
  (String, String) getMarkerPreviewImageName(int currentFloorValue, int arrivalFloorValue, String movingBetweenFloorType) {
    String markerImageName = "";
    String markerImageNameEN = "";
    if (currentFloorValue > arrivalFloorValue) {
      if(movingBetweenFloorType == "ST"){
        markerImageName = "gm_stairs_down";
        markerImageNameEN = "gm_stairs_down";
      } else if(movingBetweenFloorType == "ESC"){
        markerImageName = "gm_escalator_down";
        markerImageNameEN = "gm_escalator_down";
      } else if(movingBetweenFloorType == "EV"){
        markerImageName = "gm_elevator_down";
        markerImageNameEN = "gm_elevator_down";
      } else {
        markerImageName = "gm_down";
        markerImageNameEN = "gm_down_en";
      }
    } else {
      if(movingBetweenFloorType == "ST"){
        markerImageName = "gm_stairs_up";
        markerImageNameEN = "gm_stairs_up";
      } else if(movingBetweenFloorType == "ESC"){
        markerImageName = "gm_escalator_up";
        markerImageNameEN = "gm_escalator_up";
      } else if(movingBetweenFloorType == "EV"){
        markerImageName = "gm_elevator_up";
        markerImageNameEN = "gm_elevator_up";
      } else {
        markerImageName = "gm_up";
        markerImageNameEN = "gm_up_en";
      }
    }
    return (markerImageName, markerImageNameEN);
  }

  /// 카드뷰에서 사용하는 마커이미지를 정의하기위한 함수입니다.
  /// 현재는 경로미리보기만 사용하므로, 위/아래의 설정만있고, 더이상 업데이트가 안되어 있습니다.
  String getMarkerImageName(String defaultImageName, int currentFloorValue, int arrivalFloorValue) {
    String markerImageName = defaultImageName;
    if (currentFloorValue > arrivalFloorValue) {
      if(getUserLanguageCode() == 'ko'){
        markerImageName = "gm_down";
      } else {
        markerImageName = "gm_down_en";
      }
    } else {
      if(getUserLanguageCode() == 'ko'){
        markerImageName = "gm_up";
      } else {
        markerImageName = "gm_up_en";
      }
    }
    return markerImageName;
  }

  /// floorUid 와 floorList 를 전달받아서 현재층의 값을 받아옵니다.
  /// 1층이면 1, 2층이면 2, ...
  int findKeyByValue(String value, Map<int, String> map) {
    for (var entry in map.entries) {
      if (entry.value == value) {
        return entry.key;
      }
    }
    // 값이 없을 경우 -1이나 다른 값을 반환할 수도 있습니다.
    return -1;
  }

  // 경로미리보기에서 - ST, ESC, EV 위로, 아래로, 탑승/하차 마커 클릭 층이동 함수를 정의합니다.
  String? moveToFloorUpDownMarkerClick(String nodeUid) {
    // nodeUid 에 ":" 가 포함되어있는지 체크
    if (nodeUid.contains(":")) {
      // 층간노드
      for (int i = 1; i < movingPathDTO.value!.fullPathList.length - 1; i++) {
        final left = movingPathDTO.value!.fullPathList[i - 1].nodeUid;  /// 이전 nodeUid
        final center = movingPathDTO.value!.fullPathList[i].nodeUid;    /// 현재 nodeUid
        final right = movingPathDTO.value!.fullPathList[i + 1].nodeUid; /// 다음 nodeUid
        // 현재 nodeUid
        if (nodeUid == center) {
          /// 현재 nodeUid 와 다음 nodeUid 에 ":" 값이 존재한다면, 다음층으로 층을 바꿔줍니다.
          if (!left.contains(":") && center.contains(":") && right.contains(":")) {
            return movingPathDTO.value!.fullPathList[i + 1].floorUid;
          }
          /// 현재 nodeUid 와 이전 nodeUid 에 ":" 값이 존재한다면, 이전층으로 층을 바꿔줍니다.
          if (left.contains(":") && center.contains(":") && !right.contains(":")) {
            return movingPathDTO.value!.fullPathList[i - 1].floorUid;
          }
        }
      }
    }
    return null;
  }

  /// SourceDTO/SymbolLayOutDTO 를 사용하면서 사용하지 않는 함수입니다.
  // 한영변경을 위해서 영문/한글 두개 다 Properties 에 넣어둬야함.
  (String, String) getNameFromLatLngDTO({required LatLngDTO latLngDTO}) {
    String pointName = "";
    String pointNameEN = "";
    if (latLngDTO.poiUid != null) {
      POIDTO? poi = ValueStateController.instance.getPOIDataList(poiUid: latLngDTO.poiUid).firstOrNull;
      if (poi != null) {
        if((buildingDTO.value?.displayMapNumber == true) && poi.poiAreaUid != null){
          pointName = "(${poi.poiAreaUid}) ${poi.name}";
          pointNameEN = "(${poi.poiAreaUid}) ${poi.nameEN}";
        } else {
          pointName = "${poi.name}";
          pointNameEN = "${poi.nameEN}";
        }
      }
    }
    return (pointName, pointNameEN);
  }

  /// NodeDTO 를 통해서 현재위치의 POIDTO의 이름을 가져옵니다.
  (String, String) getNameFromNodeDTO({required NodeDTO nodeDTO}) {
    String pointName = "";
    String pointNameEN = "";
    // nodeType 이 poiType 이 아니면 return
    if(nodeDTO.nodeType != NodeAndEdgeType.poi){ return (pointName,pointNameEN);}
    POIDTO? poi = ValueStateController.instance.getPOIDataList(poiUid: "${buildingDTO.value?.buildingUid}:${nodeDTO.nodeUid}").firstOrNull;
    if (poi != null) {
      // displayMapNumber 는 스튜디오에서 설정해주는 값 입니다. poiAreaUid 를 표시할 것인지 말 것인지를 bool 값으로 가져옵니다.
      if(((buildingDTO.value?.displayMapNumber == true) && poi.poiAreaUid != null)){
        pointName = "(${poi.poiAreaUid}) ${poi.name}";
        pointNameEN = "(${poi.poiAreaUid}) ${poi.nameEN}";
      } else {
        pointName = "${poi.name}";
        pointNameEN = "${poi.nameEN}";
      }
    }
    return (pointName, pointNameEN);
  }

  /// WebViewXController와 context 초기화를 위한 함수
  void createWebViewController({required BuildContext rawContext, required WebViewXController webController}) {
    webViewXController = webController;
    context =rawContext;
  }

  /// FreeGrowMapboxJavaScript().initialData : JS 를 정의하기위한 함수.
  String createInitialJavaScript(BuildContext context) {

    /// 현재 해상도에 따라 initialZoom 이 달라지므로 정의해줍니다.
    bool mobileResolution = Responsive().check(context) == MapsDevice.mobile;

    // 센터위치, mobile&web 초기줌, 초기회전값, 최소&최대줌, poiAreaUid 표기상태, kioskMode 를 받아 초기화시켜줍니다.
    return FreeGrowMapboxJavaScript().initialData(
        centerLatLng: buildingDTO.value?.cenLatLng ?? getSelectedFloorCenterLatLng(),
        initialMobileZoom: buildingDTO.value?.initMapZoomForMobile ?? 15,
        initialWebZoom: buildingDTO.value?.initMapZoomForWeb ?? 15,
        initBearing: (ValueStateController.instance.productDTO.value != null) ? ValueStateController.instance.productDTO.value?.initAngle : buildingDTO.value?.initMapRotateAngle ?? 0,
        minZoom: buildingDTO.value?.mapMinZoom ?? 15,
        maxZoom: buildingDTO.value?.mapMaxZoom ?? 21,
        isBoothNumberDisplayed : buildingDTO.value?.displayMapNumber ?? false,
        mobileResolution: mobileResolution,
        kioskMode: kioskMode);
  }

  /// 현재 층의 중심점 LatLng 을 계산하는 함수 입니다.
  /// 현재 빌딩의 모든 층 데이터를 가져와서 왼쪽 최소 LatLng 과 오른쪽 최대 LatLng 을 계산해 중심점을 돌려줍니다.
  LatLngDTO? getSelectedFloorCenterLatLng() {
    final poiList = ValueStateController.instance.getPOIDataList(floorUid: selectedFloor.value!.floorUid);

    if(poiList.isNotEmpty){
      final latList = [];
      final lngList = [];
      for (var poi in poiList) {
        if (poi.position != null) {
          latList.add(poi.position!.lat);
          lngList.add(poi.position!.lng);
        }
      }
      latList.sort();
      lngList.sort();
      final minLat = latList.first;
      final minLng = lngList.first;
      final maxLat = latList.last;
      final maxLng = lngList.last;

      final xPos = (minLat + maxLat) / 2;
      final yPos = (minLng + maxLng) / 2;

      return LatLngDTO(lat: xPos, lng: yPos);
    } else {
      // 층들이 없다면 현재 선택된 층으로 계산
      final latLngBounds = selectedFloor.value?.latLngBounds;
      double xPos = ((latLngBounds?.bottomLeft?.lat ?? 0) + (latLngBounds?.topRight?.lat ?? 0)) / 2;
      double yPos = ((latLngBounds?.bottomLeft?.lng ?? 0) + (latLngBounds?.topRight?.lng ?? 0)) / 2;

      return LatLngDTO(lat: xPos, lng: yPos);
    }
  }

  /// mapResize 를 통해서 처음에 안보이거나 그려지지 않았던 부분을 다시 리셋해서 그립니다.
  void mapResize() {
    if (onMapboxLoaded == true) {
      webViewXController?.callJsMethod('mapResize', []);
    }
  }

  /// 층이 바뀌면 지도 이미지와 normalSymbolID 를 다시 그려주는 부분입니다.
  /// whenInit 은 처음 지도의 범위를 제한해주기 위해서 사용합니다.
  /// 이후에 다시 그릴 때의 whenInit 값은 false 입니다.
  Future<void> updateMapData({required bool whenInit}) async {
    List<POIDTO> curFloorPOIList =
    ValueStateController.instance.getPOIDataList(buildingUid: buildingDTO.value?.buildingUid, floorUid: selectedFloor.value!.floorUid);
    setFilterPlanImage(selectedFloor.value!.floorUid);

    if(whenInit == true){
      // 현재 빌딩의 모든 층을 가져와서 모든 층 중에 가장 큰값 작은값 latLngBounds 가져오기
      List<FloorPlanDTO>? floorPlanList = ValueStateController.instance.getFloorPlanList();
      List<LatLngBoundsDTO>? boundsList = floorPlanList?.map((floorPlan) => floorPlan.latLngBounds).cast<LatLngBoundsDTO>().toList();

      LatLngBoundsDTO? latLngBounds = getMinMaxLatLngBounds(boundsList);
      // latLngBounds 이 값의 대각선을 구해서 2배로 넘겨주기
      if(latLngBounds != null) {
        double scale = 2;
        LatLngBoundsDTO newBounds = changeScaleLatLngBounds(latLngBounds, scale);
        if(newBounds.bottomLeft != null && newBounds.topRight != null){
          setBoundsScreen(newBounds);
        }
      }
    }

    setPOIData(curFloorPOIList);

    /// 초기 Parameter로 값이 변경된 상태로 들어오기떄문에 listen에서 작동되지않아 초기 실행후 한번 초기값으로 설정함 ///
    /// selectedFloor 이 변경되면 그때마다 아래의 데이터들은 지워지거나 그려져야함.
    updateCandidatePOI(candidatePOI);
    updateSelectedPOI(selectedPOI.value);
    updateStartPoint(startPoint.value);
    updateEndPoint(endPoint.value);
    updateStopPlaceList(stopPlaceList);
    await Future.delayed(Duration(milliseconds: 100));
    /// MovingPathDTO 는 계산이 조금 필요하므로 딜레이를 주었음.
    updateMovingPathDTO(movingPathDTO.value);
  }

  /// setFloorPlanImages 에서 지도의 이미지를 받는데, 지도의 이미지에 floorUid 를 각각 넣어두고,
  /// 해당 층의 floorUid 만 properties 에서 접근하여 층 Filter 를 걸어주어 보여주도록 합니다.
  void setFilterSymbols(double zoomLevel){
    print("setFilterSymbols!");
    webViewXController?.callJsMethod('setFilterSymbols', [jsonEncode(zoomLevel)]);
  }

  /// 지도범위를 제한해주기 위해 값을 구하는 함수.
  /// LatLngBoundsDTO => bottomLeft, topRight 값만 들어가있어도 가능함.
  /// scaleValue 는 키워주고싶은 스케일 값
  LatLngBoundsDTO changeScaleLatLngBounds(LatLngBoundsDTO originalBounds, double scaleValue) {
    // 중앙점 구하기
    if (originalBounds.bottomLeft != null && originalBounds.topRight != null) {
      double centerLat = (originalBounds.bottomLeft!.lat + originalBounds.topRight!.lat) / 2;
      double centerLng = (originalBounds.bottomLeft!.lng + originalBounds.topRight!.lng) / 2;
      LatLngDTO center = LatLngDTO(lat: centerLat, lng: centerLng);
      // 대각선 길이 구하기
      double diagonalDistance = sqrt(pow(originalBounds.topRight!.lat - originalBounds.bottomLeft!.lat, 2) + pow(originalBounds.topRight!.lng - originalBounds.bottomLeft!.lng, 2));
      // 스케일 키우기
      LatLngBoundsDTO newBounds = LatLngBoundsDTO(
          bottomLeft: LatLngDTO(
              lat: center.lat - diagonalDistance * scaleValue / 2,
              lng: center.lng - diagonalDistance * scaleValue / 2),
          topRight: LatLngDTO(
              lat: center.lat + diagonalDistance * scaleValue / 2,
              lng: center.lng + diagonalDistance * scaleValue / 2));

      // 꼭지점 계산 ( 남서 , 동북 )
      newBounds.bottomLeft = LatLngDTO(lat: newBounds.bottomLeft!.lat, lng: newBounds.bottomLeft!.lng);
      newBounds.topRight = LatLngDTO(lat: newBounds.topRight!.lat, lng: newBounds.topRight!.lng);
      return newBounds;
    } else {
      return LatLngBoundsDTO();
    }
  }

  /// 언어설정 변경을 위한 함수
  void setMarkerLanguage(BuildContext context) {
    this.context = context;
    String languageCode = context.locale.languageCode;
    webViewXController?.callJsMethod('setLanguage', [languageCode]);
  }

  /// 모든 층 이미지 설정하기 ///
  Future<void> setFloorPlanImages(Rxn<FloorPlanDTO> selectedFloor) async {

    // ========================= fill-extrusion 테스트 코드 =========================================================

    // // 임시로 파일을 가져옴.
    // // 나중에 백엔드에서 함수형태로 뱉어줄것임.
    // String geoJsonPolygon = await rootBundle.loadString("1F_polygon.json");
    // Map<String, dynamic> floorImagesPolygon = jsonDecode(geoJsonPolygon);
    // List<dynamic> floorPolygonFeatures = floorImagesPolygon["features"];
    //
    //
    // print("floorPolygonFeatures :: ${jsonEncode(floorPolygonFeatures)}");
    // webViewXController?.callJsMethod('setFloorPlanImagesTest', [jsonEncode(floorPolygonFeatures)]);
    // ================================================================================================================

    // 모든 층 이미지 받기
    Map<String, dynamic> floorImages = ValueStateController.instance.getFloorImageMap();

    List<dynamic> floorImageValuesList = [...floorImages.values];
    List<String> floorImageKeysList = [...floorImages.keys];


    /// 각 층마다 floorUid 설정
    FeatureCollection<GeometryObject> newPlanImageCollection = FeatureCollection<GeometryObject>(features: []);
    FeatureCollection<GeometryObject> floorImage;
    for(int i = 0 ; i < floorImageValuesList.length ; i++){
      floorImage = FeatureCollection.fromJson(floorImageValuesList[i]);
      for(int j = 0 ; j < floorImage.features.length; j++){
        floorImage.features[j].properties?["floorUid"] = floorImageKeysList[i];
      }
      newPlanImageCollection.features.addAll(floorImage.features);
      floorImage.features.clear();
    }

    // print("newPlanImageCollection :: ${jsonEncode(newPlanImageCollection)}");

    // Key, Value 에 맞는 List 로 보내기
    webViewXController?.callJsMethod('setFloorPlanImages', [jsonEncode(newPlanImageCollection)]);
    if(selectedFloor.value?.floorUid != null){
      await setFilterPlanImage(selectedFloor.value!.floorUid);
    }
  }

  /// 해당층의 Image 만 필터해주기
  Future<void> setFilterPlanImage(String floorUid) async {
    webViewXController?.callJsMethod('setFilterPlanImage', [floorUid]);
  }

  /// normalSymbol POI 데이터를 정의해주는 함수.
  Future<void> setPOIData(List<POIDTO> poiList) async {
    // importanceLevel 에 따른 그룹화를 정의해줍니다.
    // 자회사/단체관 poiAreaUid 찾아서 minzoom/maxzoom 설정 //
    // fixme 여기 filter 걸리는 심볼의 적당한 거리 찾아보기.
    // fixme _G 의 경우 적당히 맞춰놓긴 했는데 매번 수정할거 같음.
    // fixme 나중에 스튜디오에서 수정되면 좋을거 같음.
    if(buildingDTO.value?.mapMinZoom != null && buildingDTO.value?.mapMaxZoom != null){
      for (var poiDTO in poiList) {
        if(poiDTO.poiAreaUid != null){
          final poiAreaUidString = poiDTO.poiAreaUid;
          if(poiAreaUidString?.substring(poiAreaUidString.length-2) == "_G"){
            poiDTO.minzoom = (buildingDTO.value!.mapMinZoom! - 0.5);
            poiDTO.maxzoom = (buildingDTO.value!.mapMaxZoom! - ((buildingDTO.value!.mapMaxZoom! - buildingDTO.value!.mapMinZoom!) - 4));
          } else if (poiAreaUidString?.substring(poiAreaUidString.length-2) == "_A") {
            poiDTO.maxzoom = (buildingDTO.value!.mapMaxZoom!);
          } else {
            poiDTO.maxzoom = (buildingDTO.value!.mapMaxZoom!);
          }
        }
      }
    }

    List<SourceDTO> sourceList = MapboxConstants.getPoiSource(poiList, selectedFloor.value!.floorUid);
    SymbolLayOutDTO symbolLayOutDTO = MapboxConstants.getPoiLayer();

    webViewXController?.callJsMethod('setPOIData', [
      jsonEncode(sourceList),
      jsonEncode(symbolLayOutDTO),
      (getUserLanguageCode())
    ]);
  }

  /// 출발지를 설정하는 함수
  Future<void> setStartPoint(LatLngDTO? latLngDTO) async {
    String startPointName;
    String startPointNameEN;

    (startPointName, startPointNameEN) = getPointName(latLngDTO?.poiUid);

    // 둘다 혹시라도 비어있다면 출발점 or From
    if(startPointName.isEmpty || startPointNameEN.isEmpty){
      startPointName = "출발점";
      startPointNameEN = "From";
    }

    SourceDTO startSource = MapboxConstants.getStartPointSource(LatLngDTO(lat: latLngDTO!.lat, lng: latLngDTO.lng), startPointName,startPointNameEN);
    SymbolLayOutDTO symbolLayOutDTO = MapboxConstants.getStartPointLayer();

    webViewXController?.callJsMethod(
        'setStartPoint', [jsonEncode([startSource]), jsonEncode(symbolLayOutDTO), getUserLanguageCode()]);
  }

  /// 도착지를 설정하는 함수
  Future<void> setEndPoint(LatLngDTO? latLngDTO) async {
    String endPointName;
    String endPointNameEN;

    (endPointName, endPointNameEN) = getPointName(latLngDTO?.poiUid);

    // 둘다 혹시라도 비어있다면 도착점 or To
    if(endPointName.isEmpty || endPointNameEN.isEmpty){
      endPointName = "도착점";
      endPointNameEN = "To";
    }

    SourceDTO endSource = MapboxConstants.getEndPointSource(LatLngDTO(lat: latLngDTO!.lat, lng: latLngDTO.lng), endPointName, endPointNameEN);
    SymbolLayOutDTO symbolLayOutDTO = MapboxConstants.getEndPointLayer();

    webViewXController?.callJsMethod(
        'setEndPoint', [jsonEncode([endSource]), jsonEncode(symbolLayOutDTO), getUserLanguageCode()]);
  }

  /// poiUid 를 통해서 현재 POI 의 이름을 가져옵니다.
  /// 가져온 poi 를 통해서 한글과 영어이름을 돌려줍니다.
  (String,String) getPointName(String? poiUid){
    String pointName = "";
    String pointNameEN = "";
    if (poiUid != null) {
      POIDTO? poi = ValueStateController.instance.getPOIDataList(poiUid: poiUid).firstOrNull;
      if (poi != null) {
        pointName = (buildingDTO.value?.displayMapNumber == true && poi.poiAreaUid != null) ? "(${poi.poiAreaUid}) ${poi.name}" : "${poi.name}";
        pointNameEN = (buildingDTO.value?.displayMapNumber == true && poi.poiAreaUid != null) ? "(${poi.poiAreaUid}) ${poi.nameEN}" : "${poi.nameEN}";
      }
    }
    return (pointName,pointNameEN);
  }

  /// 경유지를 설정합니다.
  Future<void> setStopOverPoint(List<POIDTO> poiList) async {
    // 소스생성 //
    List<SourceDTO> sourceList = MapboxConstants.getStopOverPointSource(poiList);
    // 레어이 프로퍼티 생성 //
    SymbolLayOutDTO symbolLayOutDTO = MapboxConstants.getStopOverPointLayer();

    // 경유지는 3개까지만 사용합니다.
    if (sourceList.length >= 4) {
      sourceList = sourceList.sublist(0, 3);
    }

    webViewXController?.callJsMethod('setStopOverPoint', [
      getUserLanguageCode(),
      jsonEncode(sourceList),
      jsonEncode(symbolLayOutDTO)
    ]);
  }

  /// QuickButton에 해당하는 poiList 위에 Pin 을 생성하는 함수 입니다.
  Future<void> getCandidatePOIList(List<POIDTO> poiList) async {
    if(selectedFloor.value != null){
      List<POIDTO> selectedFloorPoiList = poiList.where((poiData) => poiData.floorUid == selectedFloor.value?.floorUid).toList();
      List<SourceDTO> sourceList = MapboxConstants.getCandidatePOISource(selectedFloorPoiList);
      SymbolLayOutDTO symbolLayOutDTO = MapboxConstants.getCandidatePOILayer();
      webViewXController?.callJsMethod('getCandidatePOIList', [jsonEncode(sourceList), jsonEncode(symbolLayOutDTO),getUserLanguageCode()]);
    }
  }

  /// 경로안내시 회색라인을 생성하는 함수입니다.
  Future<void> setPathFinding(List<List<NodeDTO>>? fullPathList) async {
    isPathFindingMode = true;
    webViewXController?.callJsMethod('setPathFinding', [jsonEncode(fullPathList), selectedFloor.value?.floorUid,jsonEncode(grayLine)]);
  }

  /// 경로안내시 index 와 cardViewList 를 받아서 경로안내 애니메이션을 생성해줍니다.
  Future<void> moveToPOIaddDashedAnim(int index, List<CardViewData> cardViewList) async {
    // 현재 CardView의 nodeList 안에 각각의 node 중에 가장 큰값과 가장 작은값을 가져온다.
    Map<String, LatLngDTO>? result = getMinMaxLatLngByNodeList(cardViewList[index].nodeList);
    final zoom = getCalculateZoomLevel(result);

    // 두 Node 사이의 각도를 계산해서 bearing 을 반환합니다.
    // 그래서 경로안내시 첫번째노드와 두번째 노드의 각도를 반환해줬습니다.
    final bearing = Geolocator.bearingBetween(
      cardViewList[index].nodeList[0].pos.lat,
      cardViewList[index].nodeList[0].pos.lng,
      cardViewList[index].nodeList[1].pos.lat,
      cardViewList[index].nodeList[1].pos.lng,
    );

    // 카드뷰 노드의 poiName
    String? startPointName = cardViewList[index].startPoiName;
    String? endPointName = cardViewList[index].endPoiName;

    // 카드뷰 리스트를 통해서 위로,아래로,출발,도착,dot 전달해주기
    var (startMarkerImageName, endMarkerImageName) = getCardViewMarkerName(index, cardViewList);

    /// 위로, 아래로 마커이동을 위한 CardView Index 저장
    currentCardViewIndex = index;
    webViewXController?.callJsMethod('moveToPOIaddDashedAnim', [
      jsonEncode(index),
      jsonEncode(cardViewList),
      jsonEncode(stopPlaceList.value),
      startPointName,
      endPointName,
      startMarkerImageName,
      endMarkerImageName,
      jsonEncode(zoom),
      jsonEncode(bearing),
      getUserLanguageCode(),
    ]);
  }

  /// 현재 CardView의 nodeList 안에 각각의 node 중에
  /// 가장 큰값(maxLatLng)과 가장 작은값(minLatLng) 을 가져와서 zoomLevel 을 계산하여 돌려줍니다.
  double getCalculateZoomLevel(Map<String, LatLngDTO>? result) {
    // bearing , pitch 계산해서 넘겨주기.
    // 카메라 이동을 위해서 bearing과 zoom을 구해서 넘겨줌.
    final distance =
    Geolocator.distanceBetween(result!['minLatLng']!.lat, result['minLatLng']!.lng, result['maxLatLng']!.lat, result['maxLatLng']!.lng);
    const zoomConst = 300;
    final zoom = log(78271 * cos(result['minLatLng']!.lat * pi / 180) * zoomConst / distance) / log(2); // minY는 latitude, zoomConst은 적절한 줌 수준을 위한 상수,
    return zoom;
  }

  /// 카드뷰상에 시작-출발점, 위/아래 노드상에 dot Image 를 표시합니다.
  (String, String) getCardViewMarkerName(int index, List<CardViewData> cardViewList) {
    String? startMarkerImageName = "gm_dot";
    String? endMarkerImageName = "gm_dot";
    Map<int, String> floorList = ValueStateController.instance.getFloorPlanUidList();
    // index 가 0 or length-1 일 경우
    if (index == 0) {
      if (getUserLanguageCode() == "ko") {
        startMarkerImageName = "gm_start";
      } else {
        startMarkerImageName = "gm_start_en";
      }
    } else if ((cardViewList.length - 1) == index) {
      if (getUserLanguageCode() == "ko") {
        endMarkerImageName = "gm_end";
      } else {
        endMarkerImageName = "gm_end_en";
      }
    }
    // 현재 카드뷰의 첫번째 노드
    if (cardViewList[index].nodeList.first.nodeUid.contains(':')) {
      // 첫번째 노드가 ':' 이라는 말은 이전 이동수단을 찾아서 확인
      // 이전 List<NodeDTO>의 마지막 Node
      String arrivalFloorUid = cardViewList[index - 2].nodeList.last.floorUid;
      // 현재 List<NodeDTO>의 첫번째 Node
      String currentFloorUid = cardViewList[index].nodeList.first.floorUid;
      int arrivalFloorValue = findKeyByValue(arrivalFloorUid, floorList); // 도착할 층수
      int currentFloorValue = findKeyByValue(currentFloorUid, floorList); // 현재 층수
      startMarkerImageName = getMarkerImageName(startMarkerImageName, currentFloorValue, arrivalFloorValue);
    }
    // 현재 카드뷰의 마지막 노드
    if (cardViewList[index].nodeList.last.nodeUid.contains(':')) {
      // 마지막 노드가 ':' 이라는 말은 다음 이동수단을 찾아서 확인
      // 다음 List<NodeDTO>의 첫번째 Node
      String arrivalFloorUid = cardViewList[index + 2].nodeList.first.floorUid;
      // 현재 List<NodeDTO>의 마지막 Node
      String currentFloorUid = cardViewList[index].nodeList.last.floorUid;
      int arrivalFloorValue = findKeyByValue(arrivalFloorUid, floorList); // 도착할 층수
      int currentFloorValue = findKeyByValue(currentFloorUid, floorList); // 현재 층수
      endMarkerImageName = getMarkerImageName(endMarkerImageName, currentFloorValue, arrivalFloorValue);
    }

    return (startMarkerImageName, endMarkerImageName);
  }

  /// home_page.dart 쪽에서 모드가 kioskMode 일때 설정으로 사용합니다..
  void setKioskMode() {
    kioskMode = true;
  }

  // 현재 맵의 줌레벨을 가져옵니다.
  void getZoomLevel(){
    webViewXController?.callJsMethod('getZoomLevel', []);
  }

  /// 나침반 기능을 활성화 하기위한 함수입니다. - 보류로 인해 사용하지는 않습니다.
  void onEnableCompass(){
    webViewXController?.callJsMethod('onEnableCompass', []);
  }
  /// 나침반 기능을 비활성화 하기위한 함수입니다. - 보류로 인해 사용하지는 않습니다.
  void onDisableCompass(){
    webViewXController?.callJsMethod('onDisableCompass', []);
  }

  /// 카메라 회전없엠(키오스크 모드일때 필요) - 현재는 사용하지 않고있습니다.
  void fixCameraToKiosk() {
    webViewXController?.callJsMethod('fixCameraToKiosk', []);
  }

  /// 모든층의 LatLngBound 를 가져와서 가장 작은 LatLngLeftBound 와 가장 큰 LatLngRightBound 를 전달합니다.
  LatLngBoundsDTO? getMinMaxLatLngBounds(List<LatLngBoundsDTO>? boundsList){
    if (boundsList!.isEmpty) {
      debugPrint('boundsList.isEmpty');
      return null;
    }

    double? minBottomLeftLat = boundsList[0].bottomLeft?.lat;
    double? minBottomLeftLng = boundsList[0].bottomLeft?.lng;
    double? maxTopRightLat = boundsList[0].topRight?.lat;
    double? maxTopRightLng = boundsList[0].topRight?.lng;

    // 순차적으로 최대최소를 비교 후 각각의 변수에 담아줍니다.
    for (int i = 1; i < boundsList.length; i++) {
      double? bottomLeftLat = boundsList[i].bottomLeft?.lat;
      double? bottomLeftLng = boundsList[i].bottomLeft?.lng;
      double? topRightLat = boundsList[i].topRight?.lat;
      double? topRightLng = boundsList[i].topRight?.lng;
      minBottomLeftLat = min(bottomLeftLat!, minBottomLeftLat!);
      minBottomLeftLng = min(bottomLeftLng!, minBottomLeftLng!);
      maxTopRightLat = max(topRightLat!, maxTopRightLat!);
      maxTopRightLng = max(topRightLng!, maxTopRightLng!);
    }
    return LatLngBoundsDTO(bottomLeft: LatLngDTO(lat: minBottomLeftLat!,lng: minBottomLeftLng!),topRight: LatLngDTO(lat: maxTopRightLat!,lng: maxTopRightLng!));
  }

  /// 현재 CardView의 nodeList 안에 각각의 node 중에 가장 큰값과 가장 작은값을 가져옵니다.
  Map<String, LatLngDTO>? getMinMaxLatLngByNodeList(List<NodeDTO> nodeList) {
    if (nodeList.isEmpty) {
      debugPrint('nodeList.isEmpty');
      return null;
    }
    // 최대, 최소를 비교해서 각각의 변수에 담아줍니다.
    double minLat = nodeList[0].pos.lat;
    double maxLat = nodeList[0].pos.lat;
    double minLng = nodeList[0].pos.lng;
    double maxLng = nodeList[0].pos.lng;
    for (int i = 1; i < nodeList.length; i++) {
      double lat = nodeList[i].pos.lat;
      double lng = nodeList[i].pos.lng;
      minLat = min(lat, minLat);
      maxLat = max(lat, maxLat);
      minLng = min(lng, minLng);
      maxLng = max(lng, maxLng);
    }
    return {
      'minLatLng': LatLngDTO(lat: minLat, lng: minLng),
      'maxLatLng': LatLngDTO(lat: maxLat, lng: maxLng),
    };
  }

  /// LineString 경로미리보기 안에 길을 꽉채워서 보여주는 기능입니다.
  /// Mapbox 에서 지원해주는 기능입니다.
  Future<void> fitToTheBoundsOfLineString({double top = 0, double bottom = 0, double left = 0, double right = 0}) async {
    if (movingPathDTO.value != null) {
      webViewXController?.callJsMethod('fitToTheBoundsOfLineString',
          [jsonEncode(movingPathDTO.value!.fullPathList), jsonEncode(top), jsonEncode(bottom), jsonEncode(left), jsonEncode(right)]);
    }
  }

  /// 경계좌표를 전달받아서 카메라 위치가 벗어나지 못하도록 제한하는 함수.
  /// Mapbox GL JS 함수 중 setMaxBounds(Bounds) 를 사용합니다.
  /// [swLatLng] 남서 위경도
  /// [neLatLng] 북동 위경도
  Future<void> setBoundsScreen(LatLngBoundsDTO latLngBounds) async {
    final bl = latLngBounds.bottomLeft;
    final tr = latLngBounds.topRight;
    webViewXController?.callJsMethod('setBoundsScreen', [jsonEncode(bl), jsonEncode(tr)]);
  }

  /// 좌표 제한 해제하기
  /// setMaxBounds(null) 을 넣습니다.
  Future<void> deleteBoundsScreen() async {
    webViewXController?.callJsMethod('deleteBoundsScreen', []);
  }

  /// 현 위치의 위도,경도를 얻어오는 함수, 현재는 활용하지않음.
  Future<void> getBoundsToCurrentScreen() async {
    webViewXController?.callJsMethod('getBoundsToCurrentScreen', []);
  }

  /// 경로미리보기가 활성화되어있을 때 모든 경로상에 Symbol 들을 지워줍니다.
  Future<void> removeAllPathSymbols() async {
    webViewXController?.callJsMethod('removeAllPathSymbols', []);
  }

  /// 모든 경로미리보기와 경로안내, 심볼을 지워줍니다.
  Future<void> removeAllPathGuideSymbolAndLineString() async {
    isPathFindingMode = false;
    webViewXController?.callJsMethod('removeAllPathGuideSymbolAndLineString', []);
  }

  /// 해당 점으로 이동만 하는 함수 - 점프
  Future<void> jumpToCenterPoi({required POIDTO? poidto}) async {
    webViewXController?.callJsMethod('jumpToCenterPoi', [jsonEncode(poidto?.position)]);
  }

  /// 해당 점으로 이동만 하는 함수 - 플라이
  ///
  /// [speed] 값을 전달해주지 않으면 JS 상에 초기값을 가져온다.
  /// [zoom] 값을 전달해주지 않으면 현재 줌 레벨을 가져온다.
  Future<void> flyToCenterPoi({required POIDTO? poidto, double? speed, double? zoom}) async {
    webViewXController?.callJsMethod('flyToCenterPoi', [jsonEncode(poidto?.position), jsonEncode(speed), jsonEncode(zoom)]);
  }

  /// 해당 점으로 상세하게 조정해서 이동하는 함수 - 점프
  ///
  /// [LatLngDTO] LatLngDTO 필수.
  /// [zoom] 값을 전달해주지 않으면 현재 줌 레벨을 가져온다.
  /// [bearing] 값을 전달해주지 않으면 0. JS 상에 초기값으로 설정
  /// [pitch] 값을 전달해주지 않으면 0. JS 상에 초기값으로 설정
  /// [moveType]은 flyTo, jumpTo  있음
  Future<void> cameraMove({required String moveType, required LatLngDTO? latlng, double? zoom, double? bearing, double? pitch, EdgeInsets? edgeInsets}) async {
    Map<String, dynamic> camData = {};
    if (latlng != null) {
      camData.addAll({
        'center': [latlng.lng, latlng.lat],
      });
    }
    if (zoom != null) {
      camData.addAll({'zoom': zoom});
    }
    if (bearing != null) {
      camData.addAll({'bearing': bearing});
    }
    if (pitch != null) {
      camData.addAll({'pitch': pitch});
    }
    if(edgeInsets != null){
      camData.addAll({
        'padding':{
          'top':edgeInsets?.top,
          'bottom':edgeInsets?.bottom,
          'left':edgeInsets?.left,
          'right':edgeInsets?.right,
        }
      });
    }
    webViewXController?.callJsMethod('cameraMove', [moveType, jsonEncode(camData)]);
  }

  /// '현재위치'에서 카메라의 Pitch 와 Bearing 의 상태를 조정하는 함수
  ///
  /// [zoom] 값을 전달해주지 않으면 현재 줌 레벨을 가져온다.
  /// [bearing] 값을 전달해주지 않으면 0. JS 상에 초기값으로 설정
  /// [pitch] 값을 전달해주지 않으면 0. JS 상에 초기값으로 설정
  Future<void> jumpToCenterPitchAndBearing({double? zoom, double? bearing, double? pitch}) async {
    webViewXController?.callJsMethod('jumpToCenterPitchAndBearing', [jsonEncode(zoom), jsonEncode(bearing), jsonEncode(pitch)]);
  }

  /// '현재위치'에서 카메라의 Tilt 와 Bearing 의 상태를 조정하는 함수 - 플라이
  ///
  /// [zoom] 값을 전달해주지 않으면 현재 줌 레벨을 가져온다.
  /// [speed] 값을 전달해주지 않으면 0.8 으로 설정된다. JS 상에 초기값으로 설정
  /// [bearing] 값을 전달해주지 않으면 0. JS 상에 초기값으로 설정
  /// [pitch] 값을 전달해주지 않으면 0. JS 상에 초기값으로 설정
  Future<void> flyToCenterPitchAndBearing({double? zoom, double? speed, double? bearing, double? pitch}) async {
    webViewXController?.callJsMethod('flyToCenterPitchAndBearing', [jsonEncode(zoom), jsonEncode(speed), jsonEncode(bearing), jsonEncode(pitch)]);
  }

  /// 현재위치에서 zoom, pitch, bearing 을 조정합니다.
  /// 값을 넣지 않으면 현재 상태 그대로를 유지합니다.
  Future<void> resetPitchZoomBearingAtCenter({double? zoom, double? bearing, double? pitch}) async {
    webViewXController?.callJsMethod('resetPitchZoomBearingAtCenter', [jsonEncode(zoom), jsonEncode(bearing), jsonEncode(pitch)]);
  }

  /// 현재 언어상태를 가져옵니다.
  String getUserLanguageCode() {
    return context?.locale.languageCode??'ko';
  }

  /// List<NodeDTO> 를 깊은복사 하는 함수입니다.
  List<NodeDTO> nodeListDeepCopy(List<NodeDTO> original) {
    // 객체를 JSON 문자열로 인코딩한 후 다시 디코딩하여 새로운 인스턴스를 생성
    final List<NodeDTO> list = [];
    for (var value in original) {
      final json = jsonDecode(jsonEncode(value));
      list.add(NodeDTO.fromJson(json));
    }
    return list;
  }

  /// List<POIDTO> 를 깊은복사 하는 함수입니다.
  List<POIDTO> poiDeepCopy(List<POIDTO> original) {
    // 객체를 JSON 문자열로 인코딩한 후 다시 디코딩하여 새로운 인스턴스를 생성
    final List<POIDTO> list = [];
    for (var value in original) {
      final json = jsonDecode(jsonEncode(value));
      list.add(POIDTO.fromJson(json));
    }
    return list;
  }
}
