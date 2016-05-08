xquery version "1.0-ml";

module namespace transform = "http://marklogic.com/rest-api/transform/geo-json";

import module namespace json = "http://marklogic.com/xdmp/json" at "/MarkLogic/json/json.xqy";

declare namespace jb = "http://marklogic.com/xdmp/json/basic";

declare function transform(
  $context as map:map,
  $params as map:map,
  $content as document-node()
) as document-node()
{
  let $xml := json:transform-from-json($content)
  let $coords := $xml/jb:features/jb:json[1]/jb:geometry/jb:coordinates
  let $first-point :=
    if ($coords/jb:json[@type = 'array']) then
      $coords/jb:json/jb:json[1]
    else
      $coords

  return
    if ($first-point and $first-point/element()[2]) then
      let $wgs := convert-mercator-to-wgs84($first-point/jb:item[1], $first-point/jb:item[2])
      return
        if ($wgs[2]) then
          let $xml := element {node-name($xml)} {
            $xml/@*,
            <jb:geo-point type="string">{string-join($wgs ! string(.), " ")}</jb:geo-point>,
            $xml/element()
          }
          return document {json:transform-to-json($xml)}
        else
          $content
    else
      $content
};

declare private function convert-mercator-to-wgs84($x as xs:double, $y as xs:double) as xs:double+
{
  if ($x le 180 and $y le 90) then
    ($y, $x)
  else
    let $const := 180 div math:pi()
    let $num3 := $x div 6378137.0
    let $num4 := $num3 * $const
    let $num5 := math:floor(($num4 + 180.0) div 360.0)
    let $lon := $num4 - ($num5 * 360.0)
    let $num7 := 1.5707963267948966 - (2.0 * math:atan(math:exp((-1.0 * $y) div 6378137.0)))
    let $lat := $num7 * $const
    return ($lon, $lat)
};
