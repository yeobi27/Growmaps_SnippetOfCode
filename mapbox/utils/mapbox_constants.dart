import 'package:freegrow_backend/freegrow_backend.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import '../model/source_dto.dart';
import 'dart:math';

/// MapboxConstants 는 맵박스에서 사용되는 모든 심볼과 라인 등의 Source 나 Layout 을 미리 정의하고
/// javascript 로 전달해주기 위해서 사용됩니다.
class MapboxConstants {

  // ====================================== Mapbox 공용 사용 변수 =============================================
  static var startSymbolSortValue = 1.0;
  static var endSymbolSortValue = 1.0;
  static var stopOverSymbolSortValue = 1.0;
  static var candidateSymbolSortValue = 30.0;
  static var defaultMarkerSize = 0.4; // 기본 심볼 마커 크기, 출발,도착,경유지, 선택핀 관련
  static var initClickedMarkerSize = 0.1; // 초기화 핀클릭 마커 크기
  static var clickedMarkerSize = 0.3; // 핀 클릭된 마커 크기
  static var initCandidateMarkerSize = 0.1; // 핀 카테고리 마커 크기
  static var clickedCandidateMarkerSize = 0.25; // 클릭된 카테고리 마커 크기
  static var startPointMarkerSize = 0.26;
  static var endPointMarkerSize = 0.26;
  static var stopPlaceMarkerSize = 0.26;
  static var dotMarkerSize = 0.3;
  static var startIconOffSet = [0, -55].cast<double>();
  static var endIconOffSet = [0, -55].cast<double>();
  static var stopOverIconOffSet = [0, -60].cast<double>();
  static var selectedPOIIconOffSet = [0, -50].cast<double>();
  static var candidatePOIIconOffSet = [0, -30].cast<double>();
  static var startTextOffSet = [0, 1].cast<double>();
  static var endTextOffSet = [0, 1].cast<double>();
  static var stopOverTextOffSet = [0, 1].cast<double>();
  static var selectedPOITextOffSet = [0, 1].cast<double>();
  static var candidateTextOffSet = [0, 1].cast<double>();
  static var normalFontOffSet = [0, 1].cast<double>();
  static var startTextSize = 14.0;
  static var endTextSize = 14.0;
  static var stopOverTextSize = 14.0;
  static var selectedPOITextSize = 14.0;
  static var candidatePOITextSize = 14.0;
  static var normalFontSize = 14.0;

  /// 아래는 LayerID 정의 입니다 ///
  static var normalLayerID = 'points';
  static var startLayerID = 'start-point-layer';
  static var endLayerID = 'end-point-layer';
  static var stopOverLayerID = 'stopover-point-layer';
  static var candidateLayerID = 'candidate-point-layer';
  static var selectedPinLayerID = 'selected-pin-layer';
  static var lineBackgroundSourceID = 'line-background-source';
  /// Noto Sans SemiCondensed 로 배열이 되어있는 이유는 로드가 안되면 다른 배열을 사용하게 하려했는데,
  /// 현재는 하나만 사용하고있습니다. 나중에 여러개를 사용하려면 해당 List 에 폰트를 넣어서 변경시켜주면 됩니다.
  static var fonts = ['Noto Sans SemiCondensed', 'Noto Sans SemiCondensed', 'Noto Sans SemiCondensed'];  // 일단 이 Noto Sans 뿐이 안써져서 사용중.

  // =========================================================================================================

  /// 출발점 Source 를 정의합니다.
  static SourceDTO getStartPointSource(LatLngDTO? latLngDTO, startPointName, startPointNameEN){
    List<LatLngDTO>? latLngDTOList = [];
    latLngDTOList.add(latLngDTO!);
    return SourceDTO(
      displayType: DisplayType.startPoint,
      shapeType: ShapeType.Point,
      layerID: MapboxConstants.startLayerID,
      latLngDTOList: latLngDTOList,
      name: startPointName,
      nameEN: startPointNameEN,
      imageName: 'gm_start',
      imageNameEN: 'gm_start_en',
      symbolSortValue: MapboxConstants.startSymbolSortValue,
      minzoom: 1,
      maxzoom: 100,
    );
  }

  /// 출발점 layout 을 정의합니다.
  static SymbolLayOutDTO getStartPointLayer(){
    return SymbolLayOutDTO(
      layerType: LayerType.symbol,
      iconSize: MapboxConstants.startPointMarkerSize,
      iconOffset: MapboxConstants.startIconOffSet,
      textFont: MapboxConstants.fonts,
      textSize: MapboxConstants.startTextSize,
      textOffset: MapboxConstants.startTextOffSet,
      textAnchor: 'top',
      iconAllowOverlap: true,
      textAllowOverlap: true,
    );
  }

  /// 도착점 Source 를 정의합니다.
  static SourceDTO getEndPointSource(LatLngDTO? latLng, endPointName, endPointNameEN){
    List<LatLngDTO>? latLngDTOList = [];
    latLngDTOList.add(latLng!);
    return SourceDTO(
      displayType: DisplayType.endPoint,
      shapeType: ShapeType.Point,
      layerID: MapboxConstants.endLayerID,
      latLngDTOList: latLngDTOList,
      name: endPointName,
      nameEN: endPointNameEN,
      imageName: 'gm_end',
      imageNameEN: 'gm_end_en',
      symbolSortValue: MapboxConstants.endSymbolSortValue,
      minzoom: 1,
      maxzoom: 100,
    );
  }

  /// 도착점 layout 을 정의합니다.
  static SymbolLayOutDTO getEndPointLayer(){
    return SymbolLayOutDTO(
      layerType: LayerType.symbol,
      iconSize: MapboxConstants.endPointMarkerSize,
      iconOffset: MapboxConstants.endIconOffSet,
      textFont: MapboxConstants.fonts,
      textSize: MapboxConstants.endTextSize,
      textOffset: MapboxConstants.endTextOffSet,
      textAnchor: 'top',
      iconAllowOverlap: true,
      textAllowOverlap: true,
    );
  }

  /// 일반 poi 심볼의 source 를 정의합니다.
  static List<SourceDTO> getPoiSource(List<POIDTO> poiList, String? floorUid){
    // 선택된 층에 데이터만 포함
    var poiData = poiList.where((element) => (element.floorUid!.compareTo(floorUid!) == 0)).toList();
    List<SourceDTO> sourceList = [];
    for(int i=0 ; i < poiData.length; i++){
      List<LatLngDTO>? latLngDTOList = [];
      latLngDTOList.add(LatLngDTO(lat: poiData[i].position!.lat, lng: poiData[i].position!.lng));
      SourceDTO sourceDTO;
      sourceDTO = SourceDTO(
        displayType: DisplayType.normalSymbol,
        shapeType: ShapeType.Point,
        layerID: MapboxConstants.normalLayerID,
        latLngDTOList: latLngDTOList,
        name: poiData[i].name,
        nameEN: poiData[i].nameEN,
        poiUid: poiData[i].poiUid,
        imageName: poiData[i].poiImage ?? "gm_booth",
        imageNameEN: poiData[i].poiImage ?? "gm_booth",
        symbolSortValue: poiData[i].importanceLevel ?? 30.0,
        poiAreaUid: poiData[i].poiAreaUid,
        minzoom: poiData[i].minzoom??1,
        maxzoom: poiData[i].maxzoom??21,
      );
      sourceList.add(sourceDTO);
    }
    return sourceList;
  }

  /// 일반 poi 심볼의 layout 을 정의합니다.
  static SymbolLayOutDTO getPoiLayer(){
    return SymbolLayOutDTO(
      layerType: LayerType.symbol,
      iconSize: MapboxConstants.defaultMarkerSize,
      textFont: MapboxConstants.fonts,
      textSize: MapboxConstants.normalFontSize,
      textOffset: MapboxConstants.normalFontOffSet,
      textAnchor: 'top',
      iconAllowOverlap: false,
      textAllowOverlap: false,
    );
  }

  /// poi 를 선택 했을때 pin 의 source 를 정의합니다.
  static SourceDTO getSelectedPOISource(POIDTO? poiDTO){
    List<LatLngDTO>? latLngDTOList = [];
    latLngDTOList.add(LatLngDTO(lat: poiDTO!.position!.lat, lng: poiDTO.position!.lng));
    return SourceDTO(
      displayType: DisplayType.selectedPOI,
      layerID: MapboxConstants.selectedPinLayerID,
      shapeType: ShapeType.Point,
      latLngDTOList: latLngDTOList,
      name: poiDTO.name,
      nameEN: poiDTO.nameEN,
      imageName: 'gm_Pin_pressed',
      imageNameEN: 'gm_Pin_pressed',
      poiUid: poiDTO.poiUid,
      symbolSortValue: 10,
      poiAreaUid: poiDTO.poiAreaUid,
      minzoom: 1,
      maxzoom: 100,
    );
  }

  /// poi 를 선택 했을때 pin 의 layout 을 정의합니다.
  static SymbolLayOutDTO getSelectedPOILayer(){
    return SymbolLayOutDTO(
      layerType: LayerType.symbol,
      iconSize: MapboxConstants.initClickedMarkerSize,
      iconOffset: MapboxConstants.selectedPOIIconOffSet,
      textFont: MapboxConstants.fonts,
      textSize: MapboxConstants.selectedPOITextSize,
      textOffset: MapboxConstants.selectedPOITextOffSet,
      textAnchor: 'top',
      iconAllowOverlap: true,
      textAllowOverlap: false,
    );
  }

  /// QuickButton 에서 사용되는 여러개의 Candidate Pin 의 Source 를 정의합니다.
  static List<SourceDTO> getCandidatePOISource(List<POIDTO> selectedFloorPoiList){
    List<SourceDTO> sourceList = [];
    for(int i=0 ; i<selectedFloorPoiList.length; i++){
      List<LatLngDTO>? latLngDTOList = [];
      // LatLng 의 경우는 해당하는 경우만 보내주기.
      latLngDTOList.add(LatLngDTO(lat: selectedFloorPoiList[i].position!.lat, lng: selectedFloorPoiList[i].position!.lng));
      SourceDTO sourceDTO = SourceDTO(
        displayType: DisplayType.candidatePOI,
        shapeType: ShapeType.Point,
        layerID: MapboxConstants.candidateLayerID,
        latLngDTOList: latLngDTOList,
        name: selectedFloorPoiList[i].name,
        nameEN: selectedFloorPoiList[i].nameEN,
        imageName: 'gm_Pin',
        imageNameEN: 'gm_Pin',
        poiUid: selectedFloorPoiList[i].poiUid,
        symbolSortValue: MapboxConstants.candidateSymbolSortValue,
        poiAreaUid: selectedFloorPoiList[i].poiAreaUid,
        minzoom: 1,
        maxzoom: 100,
      );
      sourceList.add(sourceDTO);
    }
    return sourceList;
  }

  /// 여러개의 Candidate Pin layout 을 정의합니다.
  static SymbolLayOutDTO getCandidatePOILayer(){
    return SymbolLayOutDTO(
      layerType: LayerType.symbol,
      iconSize: MapboxConstants.initCandidateMarkerSize,
      iconOffset: MapboxConstants.candidatePOIIconOffSet,
      textFont: MapboxConstants.fonts,
      textSize: MapboxConstants.candidatePOITextSize,
      textOffset: MapboxConstants.candidateTextOffSet,
      textAnchor: 'top',
      iconAllowOverlap: false,
      textAllowOverlap: false,
    );
  }

  /// 경유지 Source 를 정의합니다.
  static List<SourceDTO> getStopOverPointSource(List<POIDTO> poiList){
    List<SourceDTO> sourceList = [];
    for(int i=0 ; i<poiList.length; i++){
      List<LatLngDTO>? latLngDTOList = [];
      // LatLng 의 경우는 해당하는 경우만 보내주기.
      latLngDTOList.add(LatLngDTO(lat: poiList[i].position!.lat, lng: poiList[i].position!.lng));
      SourceDTO sourceDTO = SourceDTO(
        displayType: DisplayType.stopOverPoint,
        shapeType: ShapeType.Point,
        layerID: MapboxConstants.stopOverLayerID,
        latLngDTOList: latLngDTOList,
        name: poiList[i].name,
        nameEN: poiList[i].nameEN,
        imageName: 'gm_stop${i+1}',
        imageNameEN: 'gm_stop${i+1}_en',
        poiUid: poiList[i].poiUid,
        symbolSortValue: MapboxConstants.stopOverSymbolSortValue,
        minzoom: 1,
        maxzoom: 100,
      );
      sourceList.add(sourceDTO);
    }
    return sourceList;
  }

  /// 경유지 layout 을 정의합니다.
  static getStopOverPointLayer(){
    return SymbolLayOutDTO(
      layerType: LayerType.symbol,
      iconSize: MapboxConstants.stopPlaceMarkerSize,
      iconOffset: MapboxConstants.stopOverIconOffSet,
      textFont: MapboxConstants.fonts,
      textSize: MapboxConstants.stopOverTextSize,
      textOffset: MapboxConstants.stopOverTextOffSet,
      textAnchor: 'top',
      iconAllowOverlap: true,
      textAllowOverlap: true,
    );
  }

  /// 경로미리보기에 있는 "여러개"의 LinString, StartPoint, EndPoint 를 정의합니다.
  /// 여기서 "여러개" 라는 말은 경로가 그려질 때, 각 층마다 선과 시작점-끝점은 여러개 생길 수가 있으므로,
  /// 이를 층마다 나눠놓으면 여러개가 생성되어야 합니다. 그래서 List 로 저장해서 JS 로 전달합니다.
  static (List<SourceDTO>, List<SourceDTO>,List<SourceDTO>) getMovingPathSourceList(
      List<List<NodeDTO>>? nodeBlockList,
      List<String> startPointNames,
      List<String> startPointNamesEN,
      List<String> starMarkerImageNames,
      List<String> startMarkerImageNamesEN,
      List<String> startMarkerNodeUids,
      List<String> endPointNames,
      List<String> endPointNamesEN,
      List<String> endMarkerImageNames,
      List<String> endMarkerImageNamesEN,
      List<String> endMarkerNodeUids,
      String? floorUid){
    List<SourceDTO> lineSourceList = [];
    List<SourceDTO> startSymbolSourceList = [];
    List<SourceDTO> endSymbolSourceList = [];
    for(int i=0; i<nodeBlockList!.length;i++){
      if(nodeBlockList[i][0].floorUid == floorUid){
        // 경로를 생성할 때 "해당층만" 남기기 위함.
        List<LatLngDTO>? latLngDTOList = [];
        for(int j=0; j< nodeBlockList[i].length; j++){
          latLngDTOList.add(LatLngDTO(lat: nodeBlockList[i][j].pos.lat, lng: nodeBlockList[i][j].pos.lng));
        }

        SourceDTO lineSourceDTO = SourceDTO(
          displayType: DisplayType.path,
          layerID: MapboxConstants.lineBackgroundSourceID,
          latLngDTOList: latLngDTOList,
          shapeType: ShapeType.LineString,
          index: i,
        );
        lineSourceList.add(lineSourceDTO);  /// LineString들 Source

        SourceDTO startSymbolSourceDTO = SourceDTO(
          displayType: DisplayType.startPoint,
          shapeType: ShapeType.Point,
          layerID: (i==0)? MapboxConstants.startLayerID : "${MapboxConstants.startLayerID}$i",
          latLngDTOList: [LatLngDTO(lat: nodeBlockList[i][0].pos.lat, lng: nodeBlockList[i][0].pos.lng)], // 출발심볼
          name: startPointNames[i],
          nameEN: startPointNamesEN[i],
          imageName: starMarkerImageNames[i],
          imageNameEN: startMarkerImageNamesEN[i],
          nodeUid: startMarkerNodeUids[i],
          symbolSortValue: MapboxConstants.startSymbolSortValue,
          minzoom: 1,
          maxzoom: 100,
        );
        startSymbolSourceList.add(startSymbolSourceDTO);  /// StartPoint들 Source

        SourceDTO endSymbolSourceDTO = SourceDTO(
          displayType: DisplayType.endPoint,
          shapeType: ShapeType.Point,
          layerID: (i==nodeBlockList.length-1) ? MapboxConstants.endLayerID : "${MapboxConstants.endLayerID}$i",
          latLngDTOList: [LatLngDTO(lat: nodeBlockList[i][nodeBlockList[i].length-1].pos.lat, lng: nodeBlockList[i][nodeBlockList[i].length-1].pos.lng)], // 도착심볼
          name: endPointNames[i],
          nameEN: endPointNamesEN[i],
          imageName: endMarkerImageNames[i],
          imageNameEN: endMarkerImageNamesEN[i],
          nodeUid: endMarkerNodeUids[i],
          symbolSortValue: MapboxConstants.endSymbolSortValue,
          minzoom: 1,
          maxzoom: 100,
        );
        endSymbolSourceList.add(endSymbolSourceDTO);  /// endPoint들 Source
      }
    }
    return (lineSourceList,startSymbolSourceList,endSymbolSourceList);
  }

  /// 경로미리보기에서의 심볼들의 Source
  /// 사이즈나 오프셋이 같아서 사용중 - 나중에 맞춰서 사용할것.
  /// 호영님과 작업할 때 맞춰달라고 해야할 것. 지금은 맞춰져 있긴함.
  static SymbolLayOutDTO getSymbolsLayerInMovingPath(){
    return SymbolLayOutDTO(
      layerType: LayerType.symbol,
      iconSize: MapboxConstants.startPointMarkerSize,
      iconOffset: MapboxConstants.startIconOffSet,
      textFont: MapboxConstants.fonts,
      textSize: MapboxConstants.startTextSize,
      textOffset: MapboxConstants.startTextOffSet,
      textAnchor: 'top',
      iconAllowOverlap: true,
      textAllowOverlap: true,
    );
  }

  /// 경로안내에서 회색 두꺼운 라인의 백그라운드를 정의합니다.
  static LineLayerProperties grayLines1Property() {
    return const LineLayerProperties(
      lineCap: "round",
      lineJoin: "round",
      lineColor: "#CCEFFF",
      lineGapWidth: 14,
      lineWidth: 1,
    );
  }

  /// 경로미리보기에서 파란색 두꺼운 라인의 백그라운드를 정의합니다.
  static LineLayerProperties growmapsLine1Property() {
    return const LineLayerProperties(
      lineCap: "round",
      lineJoin: "round",
      lineColor: "#CCEFFF",
      lineGapWidth: 14,
      lineWidth: 1,
    );
  }

  /// 회색라인의 바깥쪽 얇은 흰색 라인의 속성을 정의합니다.
  static LineLayerProperties grayLines2Property() {
    return const LineLayerProperties(
      lineCap: "round",
      lineJoin: "round",
      lineColor: "#FFFFFF",
      lineWidth: 1,
      lineGapWidth: 12,
    );
  }

  /// 파란색 라인의 바깥쪽 얇은 흰색 라인의 속성을 정의합니다.
  static LineLayerProperties growmapsLine2Property() {
    return const LineLayerProperties(
      lineCap: "round",
      lineJoin: "round",
      lineColor: "#FFFFFF",
      lineWidth: 1,
      lineGapWidth: 12,
    );
  }

  /// 회색 두꺼운 라인의 속성,색을 정의합니다.
  static LineLayerProperties grayLines3Property() {
    return const LineLayerProperties(
      lineCap: "round",
      lineJoin: "round",
      lineWidth: 12,
      lineColor: "#CBD5E0",
    );
  }
  /// 파란 두꺼운 라인의 속성,색을 정의합니다.
  static LineLayerProperties growmapsLine3Property() {
    return const LineLayerProperties(
        lineCap: "round",
        lineJoin: "round",
        lineWidth: 12,
        lineColor: "#0078FE");
  }
}
