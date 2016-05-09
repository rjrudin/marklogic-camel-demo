xquery version "1.0-ml";

module namespace transform = "http://marklogic.com/rest-api/transform/gdelt";

declare function transform(
  $context as map:map,
  $params as map:map,
  $content as document-node()
) as document-node()
{
  let $dataset := map:get($params, "dataset")

  let $tokens := tokenize($content, "\t")

  let $source-url := str($tokens[61])

  (: Build the event :)
  let $event := element event {
    element GlobalEventID {$tokens[1]},
    let $date := $tokens[2]
    return element Date {
      string-join((substring($date, 1, 4), substring($date, 5, 2), substring($date, 7, 2)), "-")
    },
    str($tokens[6]) ! element Actor1Code {.},
    str($tokens[16]) ! element Actor2Code {.},
    str($tokens[27]) ! element EventCode {.},
    str($tokens[32]) ! element NumMentions {.},
    str($tokens[36]) ! element Actor1Geo_Type {.},
    str($tokens[37]) ! element Actor1Geo_Fullname {.},
    str($tokens[38]) ! element Actor1Geo_CountryCode {.},
    str($tokens[39]) ! element Actor1Geo_ADM1Code {.},
    str($tokens[44]) ! element Actor2Geo_Type {.},
    str($tokens[45]) ! element Actor2Geo_Fullname {.},
    str($tokens[46]) ! element Actor2Geo_CountryCode {.},
    str($tokens[47]) ! element Actor2Geo_ADM1Code {.},
    let $lat := str($tokens[41])
    let $lon := str($tokens[42])
    where $lat and $lon
    return element geo-point {text {$lat, $lon}},
    $source-url ! element SourceUrl {.},
    $dataset ! element Dataset {.}
  }

  (:
    See if an event exists with this same source URL, merge this one into it. Note that this works because the Camel
    split component is single-threaded. Merging duplicates becomes much more complicated when events aren't ingested
    serially.
  :)
  let $existing-event :=
    cts:search(
      collection("gdelt"),
      cts:element-value-query(xs:QName("SourceUrl"), $source-url)
    )[1]/element()

  return
    if ($existing-event) then
      let $merged-event := element {node-name($event)} {
        $existing-event/@*,
        $existing-event/element(),
        $event/GlobalEventID,
        copy-if-different($event/EventCode, $existing-event/EventCode),
        copy-if-different($event/geo-point, $existing-event/geo-point),
        copy-if-different($event/Actor1Code, $existing-event/Actor1Code),
        copy-if-different($event/Actor2Code, $existing-event/Actor2Code)
      }

      let $uri := xdmp:node-uri($existing-event)
      let $_ := xdmp:document-delete($uri)

      return document {$merged-event}

    else
      document {$event}
};

declare private function copy-if-different(
  $event-el as element(),
  $existing-event-el as element()*
) as element()?
{
  let $val := str($event-el)
  where not($val = $existing-event-el ! str(.))
  return $event-el
};

declare private function str($token) as xs:string?
{
  let $str := normalize-space(string($token))
  where string-length($str) > 0
  return $str
};
