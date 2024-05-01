import 'package:freegrow_backend/freegrow_backend.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:json_annotation/json_annotation.dart';

/// MapboxConstants 에 정의하여 설정하고, 코드의 가독성을 높이기 위해서 DTO를 사용합니다.
/// 맵박스에서 사용하는 모든 Source를 정의하기위한 SourceDTO 입니다.
class SourceDTO {
  DisplayType? displayType;
  ShapeType? shapeType; // 맵박스에서 정의된 그려지는 모양의 type 입니다.
  String? layerID;      // layerID 를 설정하기 위함.
  List<LatLngDTO>? latLngDTOList; // 심볼과 Line 등을 둘다 보완할 수 있어야하므로 List 로 정의합니다.
  String? name;   // 해당 심볼의 한글 이름을 설정합니다.
  String? nameEN; // 해당 심볼의 영어 이름을 설정합니다.
  String? imageName;  // 한글 이미지 이름을 설정합니다.
  String? imageNameEN;  // 영어 이미지 이름을 설정합니다.
  String? nodeUid;  // 해당 심볼의 nodeUid 를 설정합니다.
  String? poiUid;   // 해당 poiUid 를 설정합니다.
  double? symbolSortValue;  // 심볼의 importanceLevel 을 설정하는 변수입니다.
  String? poiAreaUid; // poiAreaUid 를 설정하는 변수입니다.
  double? minzoom;    // importanceLevel 에 따른 minZoom 을 설정하는 변수입니다.
  double? maxzoom;    // importanceLevel 에 따른 maxZoom 을 설정하는 변수입니다.
  int? index;         // index 는 경로미리보기를 위해서 선언해두었지만, 사용하진 않았습니다.

  SourceDTO({required this.displayType, required this.layerID, required this.latLngDTOList, required this.shapeType, this.name, this.nameEN, this.imageName, this.imageNameEN, this.nodeUid, this.poiUid, this.symbolSortValue, this.poiAreaUid, this.minzoom, this.maxzoom, this.index});

  /// webViewXController.callJSMethod 를 통해 값을 넘겨주고,
  /// 원하는 Value 값 형태를 넣어주고싶어서
  /// 직접 필요한 변수를 만들어 toJson 해주었습니다.
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};

    void addIfPresent(String fieldName, dynamic value) {
      if (value != null) {
        json[fieldName] = value;
      }
    }

    addIfPresent('symbolMarkerType', displayType?.displayName);
    addIfPresent('shapeType', shapeType?.displayName);
    addIfPresent('layerID', layerID);
    addIfPresent('latLngList', latLngDTOList);
    addIfPresent('name', name);
    addIfPresent('nameEN', nameEN);
    addIfPresent('imageName', imageName);
    addIfPresent('imageNameEN', imageNameEN);
    addIfPresent('nodeUid', nodeUid);
    addIfPresent('poiUid', poiUid);
    addIfPresent('symbolSortValue', symbolSortValue);
    addIfPresent('poiAreaUid', poiAreaUid);
    addIfPresent('minzoom', minzoom);
    addIfPresent('maxzoom', maxzoom);
    addIfPresent('index', index);
    return json;
  }
}

/// SymbolLayOut 의 속성을 정의하기위한 DTO 입니다.
class SymbolLayOutDTO {
  LayerType? layerType; // layerType 을 설정합니다. mapbox type 을 따라갑니다. (fill-extrusion, fill, line 등등..)
  String? iconImage;    // icon-image 를 담기위한 속성값입니다.
  double? iconSize;     // icon-size 입니다.
  List<double>? iconOffset; // icon-offset 으로 위치를 조정할 수 있습니다.
  List<String>? textFont; // Font 를 지정할 수 있습니다. List 로 넣어놓고 사용할 수 있습니다.
  double? textSize;       // text-size 입니다.
  List<double>? textOffset; // text-offset 은 textAnchor 를 기준으로 위치를 조정할 수 있습니다.
  String? textAnchor;       // text 의 기준위치를 잡아줍니다. ( ex: top, bottom, left , right )
  String? textField;        // 실제로 적히는 text 입니다.
  bool? iconAllowOverlap;   // 아이콘의 겹침 허용을 설정합니다. 기본값은 false 입니다.
  bool? textAllowOverlap;   // text 의 겹침 허용을 설정합니다. 기본값은 false 입니다.
  double? symbolSortKey;    // symbolSortValue 값이 들어가 실제로 적용될 key 값 입니다.

  SymbolLayOutDTO({this.layerType, this.iconImage, this.iconSize, this.iconOffset, this.textFont, this.textSize, this.textOffset, this.textAnchor, this.textField, this.iconAllowOverlap, this.textAllowOverlap, this.symbolSortKey});

  /// 밑에 주석된 속성값은 맵박스에서 사용하는 속성들로
  /// 나중에 SymbolLayout에 정의해줘야한다면 저런식으로 선언해서 사용하면 됩니다.
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};

    void addIfPresent(String fieldName, dynamic value) {
      if (value != null) {
        json[fieldName] = value;
      }
    }

    addIfPresent('layerType', layerType?.displayName);
    // addIfPresent('icon-opacity', iconOpacity);
    // addIfPresent('icon-color', iconColor);
    // addIfPresent('icon-halo-color', iconHaloColor);
    // addIfPresent('icon-halo-width', iconHaloWidth);
    // addIfPresent('icon-halo-blur', iconHaloBlur);
    // addIfPresent('icon-translate', iconTranslate);
    // addIfPresent('icon-translate-anchor', iconTranslateAnchor);
    // addIfPresent('text-opacity', textOpacity);
    // addIfPresent('text-color', textColor);
    // addIfPresent('text-halo-color', textHaloColor);
    // addIfPresent('text-halo-width', textHaloWidth);
    // addIfPresent('text-halo-blur', textHaloBlur);
    // addIfPresent('text-translate', textTranslate);
    // addIfPresent('text-translate-anchor', textTranslateAnchor);
    // addIfPresent('symbol-placement', symbolPlacement);
    // addIfPresent('symbol-spacing', symbolSpacing);
    // addIfPresent('symbol-avoid-edges', symbolAvoidEdges);
    addIfPresent('symbol-sort-key', symbolSortKey);
    // addIfPresent('symbol-z-order', symbolZOrder);
    addIfPresent('icon-allow-overlap', iconAllowOverlap);
    // addIfPresent('icon-ignore-placement', iconIgnorePlacement);
    // addIfPresent('icon-optional', iconOptional);
    // addIfPresent('icon-rotation-alignment', iconRotationAlignment);
    addIfPresent('icon-size', iconSize);
    // addIfPresent('icon-text-fit', iconTextFit);
    // addIfPresent('icon-text-fit-padding', iconTextFitPadding);
    addIfPresent('icon-image', iconImage);
    // addIfPresent('icon-rotate', iconRotate);
    // addIfPresent('icon-padding', iconPadding);
    // addIfPresent('icon-keep-upright', iconKeepUpright);
    addIfPresent('icon-offset', iconOffset);
    // addIfPresent('icon-anchor', iconAnchor);
    // addIfPresent('icon-pitch-alignment', iconPitchAlignment);
    // addIfPresent('text-pitch-alignment', textPitchAlignment);
    // addIfPresent('text-rotation-alignment', textRotationAlignment);
    addIfPresent('text-field', textField);
    addIfPresent('text-font', textFont);
    addIfPresent('text-size', textSize);
    // addIfPresent('text-max-width', textMaxWidth);
    // addIfPresent('text-line-height', textLineHeight);
    // addIfPresent('text-letter-spacing', textLetterSpacing);
    // addIfPresent('text-justify', textJustify);
    // addIfPresent('text-radial-offset', textRadialOffset);
    // addIfPresent('text-variable-anchor', textVariableAnchor);
    addIfPresent('text-anchor', textAnchor);
    // addIfPresent('text-max-angle', textMaxAngle);
    // addIfPresent('text-writing-mode', textWritingMode);
    // addIfPresent('text-rotate', textRotate);
    // addIfPresent('text-padding', textPadding);
    // addIfPresent('text-keep-upright', textKeepUpright);
    // addIfPresent('text-transform', textTransform);
    addIfPresent('text-offset', textOffset);
    addIfPresent('text-allow-overlap', textAllowOverlap);
    // addIfPresent('text-ignore-placement', textIgnorePlacement);
    // addIfPresent('text-optional', textOptional);
    // addIfPresent('visibility', visibility);
    return json;
  }
}

/// LineLayOut 속성을 정의하기위한 DTO입니다.
class LineLayOutDTO {
  LayerType? layerType; // layerType 을 설정합니다. (fill-extrusion, fill, line 등등..)
  String? lineCap;      // 라인이 그려졌을 때 끝부분의 형태를 정의합니다. (butt, round, square ..)
  String? lineJoin;     // 라인이 끼리 만날때 끝부분의 형태를 정의합니다. (bevel, round, miter ..)
  String? lineColor;    // 라인의 색을 정의합니다.
  double? lineWidth;    // 라인의 가운데 두께를 설정합니다.
  double? lineGapWidth; // 라인의 바깥(외부)에 선을 정의합니다.

  LineLayOutDTO({this.layerType, this.lineCap,this.lineJoin,this.lineColor,this.lineWidth,this.lineGapWidth});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};

    void addIfPresent(String fieldName, dynamic value) {
      if (value != null) {
        json[fieldName] = value;
      }
    }

    // addIfPresent('line-opacity', lineOpacity);
    addIfPresent('line-color', lineColor);
    // addIfPresent('line-translate', lineTranslate);
    // addIfPresent('line-translate-anchor', lineTranslateAnchor);
    addIfPresent('line-width', lineWidth);
    addIfPresent('line-gap-width', lineGapWidth);
    // addIfPresent('line-offset', lineOffset);
    // addIfPresent('line-blur', lineBlur);
    // addIfPresent('line-dasharray', lineDasharray);
    // addIfPresent('line-pattern', linePattern);
    // addIfPresent('line-gradient', lineGradient);
    addIfPresent('line-cap', lineCap);
    addIfPresent('line-join', lineJoin);
    // addIfPresent('line-miter-limit', lineMiterLimit);
    // addIfPresent('line-round-limit', lineRoundLimit);
    // addIfPresent('line-sort-key', lineSortKey);
    // addIfPresent('visibility', visibility);
    return json;
  }
}

/// MapboxConstants 에서 어떤 타입의 Display 인지 정의해주기 위한 Enum 열거형입니다.
/// 현재 사용하지 않지만 나중을 위해서 선언해뒀습니다.
enum DisplayType {
  normalSymbol('normalSymbol', 'normalSymbol'),
  selectedPOI('selectedPOI', 'selectedPOI'),
  candidatePOI('candidatePOI','candidatePOI'),
  startPoint('startPoint', 'startPoint'),
  endPoint('endPoint', 'endPoint'),
  stopOverPoint('stopOverPoint', 'stopOverPoint'),
  upSymbol('upSymbol', 'upSymbol'),
  downSymbol('downSymbol', 'downSymbol'),
  path('path','path'),
  undefined('undefined', '');

  const DisplayType(this.code, this.displayName);
  final String code;
  final String displayName;

  factory DisplayType.getByCode(String code){
    return DisplayType.values.firstWhere((value) => value.code == code,
        orElse: () => DisplayType.undefined);
  }
}

/// 실제로 Mapbox상에서 그려지는 Type이 어떤모양인지 정의해주는 Enum 열거형 입니다.
enum ShapeType {
  Point('Point', 'Point'),
  LineString('LineString', 'LineString'),
  Polygon('Polygon', 'Polygon'),
  MultiPolygon('MultiPolygon', 'MultiPolygon'),
  undefined('undefined', '');

  const ShapeType(this.code, this.displayName);
  final String code;
  final String displayName;

  factory ShapeType.getByCode(String code){
    return ShapeType.values.firstWhere((value) => value.code == code,
        orElse: () => ShapeType.undefined);
  }
}

/// 위와 마찬가지로 LayerType Enum 열거형 입니다.
enum LayerType {
  symbol('symbol', 'symbol'),
  line('line', 'line'),
  fill('fill', 'fill'),
  fillExtrusion('fill-extrusion', 'fill-extrusion'),
  undefined('undefined', '');

  const LayerType(this.code, this.displayName);
  final String code;
  final String displayName;

  factory LayerType.getByCode(String code){
    return LayerType.values.firstWhere((value) => value.code == code,
        orElse: () => LayerType.undefined);
  }
}