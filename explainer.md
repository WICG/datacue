# DataCue Explainer

## Introduction

HTTP Live Streaming (HLS) and MPEG Dynamic Adaptive Streaming over HTTP (MPEG-DASH) are the two main adaptive streaming formats in use on the web today. The media industry is coverging on the use of [MPEG Common Media Application Format (CMAF)](https://www.iso.org/standard/71975.html) as the common media delivery format. HLS, MPEG-DASH, and MPEG CMAF all support delivery timed metadata, i.e., metadata information that is synchronized to the audio or video media. Timed metadata can be used to support use cases such as dynamic content replacement, ad insertion, or presentation of supplemental content alongside the audio or video, or more generally, making changes to a web page, or executing application code triggered from JavaScript events, at specific points on the media timeline of an audio or video media stream.

The data may be carried either "in-band", meaning that they are delivered within the audio or video media container or multiplexed with the media stream, or "out-of-band", meaning that they are delivered externally to the media container or media stream. This explainer proposes bringing support for such timed metadata to the web platform, in particular for MPEG-DASH `emsg` in-band events.

## Use cases

Some example use cases include display of social media feeds corresponding to a live video stream such as a sporting event, banner advertisements for sponsored content, accessibility-related assets such as large print rendering of captions, and display of track titles or images alongside an audio stream.

The following sections describe a few use cases in more detail.

### Dynamic content insertion

A media content provider wants to allow insertion of content, such as personalised video, local news, or advertisements, into a video media stream that contains the main program content. To achieve this, timed metadata is used to describe the points on the media timeline, known as splice points, where switching playback to inserted content is possible.

The Society for Cable and Televison Engineers (SCTE) specification [Digital Program Insertion Cueing for Cable (SCTE-35)](https://www.scte.org/SCTEDocs/Standards/SCTE%2035%202019r1.pdf) defines a data cue format for describing such insertion points. Use of these cues in MPEG-DASH and HLS streams is described in SCTE-35, sections 12.1 and 12.2.

### Lecture recording with slideshow

An HTML page contains title and information about the course or lecture, and two frames: a video of the lecturer in one and their slides in the other. Each timed metadata cue contains the URL of the slide to be presented, and the cue is active for the time range over which the slide should be visible.

### Audio stream with titles and images

A media content provider wants to provide visual information alongside an audio stream, such as an image of the artist and title of the current playing track, to give users live information about the content they are listening to.

Examples include [HLS timed metadata](https://developer.apple.com/library/archive/documentation/AudioVideo/Conceptual/HTTP_Live_Streaming_Metadata_Spec/Introduction/Introduction.html), which uses in-band ID3 metadata to carry the image content, and RadioVIS in [DVB-DASH, section 9.1.7](https://www.etsi.org/deliver/etsi_ts/103200_103299/103285/01.02.01_60/ts_103285v010201p.pdf), which defines in-band event messages that contain image URLs and text messages to be displayed, with information about when the content should be displayed in relation to the media timeline.

### Control messages for media streaming clients

A media streaming server uses timed metadata to send control messages to media client library, such as [dash.js](https://github.com/Dash-Industry-Forum/dash.js/wiki). Typically, segmented streaming protocols such as HLS and MPEG-DASH make use of a manifest document that informs the client of the available encodings of a media stream, e.g., the Media Presentation Description (MPD) document in MPEG-DASH.

Should any of the content in the manifest document need to change, the client should refresh it by requesting an updated copy from the server. Section 5.10.4 of the [MPEG-DASH specification](https://standards.iso.org/ittf/PubliclyAvailableStandards/c065274_ISO_IEC_23009-1_2014.zip) describes an event type that is used to notify a client application. An in-band `emsg` event is used as an alternative to setting a cache duration in the response to the HTTP request for the manifest, so the client can refresh the MPD when it actually changes, as opposed to waiting for a cache duration expiry period to elapse. This also has the benefit of reducing the load on HTTP servers caused by frequent server requests.

### Synchronized map animations

A user records footage with metadata, including geolocation, on a mobile video device, e.g., drone or dashcam, to share on the web alongside a map, e.g., OpenStreetMap.

WebVMT is an open format for metadata cues, synchronized with audio or video media, that can be used to drive an online map rendered in a separate HTML element alongside the media element on the web page. The media playhead position controls presentation and animation of the map, e.g., pan and zoom, and allows annotations to be added and removed, e.g., markers, at specified times during media playback. Control can also be overridden by the user with the usual interactive features of the map at any time, e.g., zoom. Concrete examples are provided by the [tech demos at the WebVMT website](http://webvmt.org/demos).

### Media metadata search results

A user searches for online media matching certain metadata conditions, for example within a given distance of a geographic location or an acceleration profile corresponding to a traffic accident. Results are returned from a remote server using a RESTful API as a list in JSON format.

It should be possible for search results to be represented as media in the user agent, with linked metadata presented as `DataCue` objects programmatically to provide a common interface within the client web browser. Further details are given in the video metadata search experiments, proposed in the [OGC](http://www.opengeospatial.org) Ideas GitHub, to return [frames](https://github.com/opengeospatial/ideas/issues/91) and [clips](https://github.com/opengeospatial/ideas/issues/92)

> NOTE: Whether this use case requires any changes to the user agent or not is unclear without further investigation. If no changes are required, this capability should be demonstrated and the use case listed as a non-goal.

### Media analysis visualization

A video image analysis system processes a media stream to detect and recognize objects shown in the video. This system generates metadata describing the objects, including timestamps that describe the when the objects are visible, together with position information (e.g., bounding boxes). A web application then uses this timed metadata to overlay labels and annotations on the video using HTML and CSS.

## HTTP adaptive streaming

HTTP adaptive streaming (HLS and MPEG-DASH) involves dividing the audio and video stream into small segments, each typically of a few seconds duration. Different encodings of the same content, known as representations, can be made available at varying quality levels (video resolution, bit rate), to allow a client application to select the most appropriate encoding for the playback device, as well as vary the bitrate in order to maintain continuous playback in response to changing network bandwidth conditions. These representations, and details of how to request the media segments are described in a manifest document.

Some user agents (notably Safari and HbbTV) include native support for adaptive streaming playback, rather than through a web application. In these cases, we need the user agent to expose to web applications any timed metadata cues that are carried either in-band with the media, or out-of-band via the manifest document.

Other user agents (Chrome, Edge, and Firefox) support adaptive streaming playback via [Media Source Extensions](https://www.w3.org/TR/media-source/). Here, a web application reads the manifest document, then requests the media segments and uses Media Source Extensions to pass the media to the user agent for playback. With these user agents, out-of-band timed metadata cues (i.e., those carried in the manifest document) must be created by the web application. In-band timed metadata cues may be created either by the web application, by parsing the media content before passing it to MSE using `appendBuffer()`, or by the user agent when it receives and decodes the media content from the web application.

## In-band timed metadata processing

The exact set of in-band timed metadata formats that we would aim to support is to be decided. MPEG DASH MPD and `emsg` events are a requirement, due to their inclusion in MPEG CMAF. We expect to discuss which other events to standardise, particularly HLS timed metadata, as part of the incubation work.

In addition to specifying a new `DataCue` API, we anticipate specifying the handling of in-band timed metadata in a separate set of specifications, following a registry approach with one specification per media format that describes the timed metadata details for that format, similar to the [Media Source Extensions Byte Stream Format Registry](https://www.w3.org/TR/mse-byte-stream-format-registry/). Another approach could be to update [Sourcing In-band Media Resource Tracks from Media Containers into HTML](https://dev.w3.org/html5/html-sourcing-inband-tracks/), either in its current form as a single document, or splitting it by media format and adding a registry.

## Proposed API and example code

The proposed API is based on the existing text track support in HTML and WebKit's `DataCue`. This extends the [HTML5 `DataCue` API](https://www.w3.org/TR/2018/WD-html53-20181018/semantics-embedded-content.html#text-tracks-exposing-inband-metadata) with two attributes to support non-text metadata, `type` and `value` (see IDL [here](https://trac.webkit.org/browser/webkit/trunk/Source/WebCore/html/track/DataCue.idl)):

```
interface DataCue : TextTrackCue {
    attribute ArrayBuffer data; // Always empty

    // Proposed extensions.
    attribute any value;
    readonly attribute DOMString type;
};
```

`type`: A string identifying the type of metadata:

| Type                       | Purpose             |
| -------------------------- | ------------------- |
| `com.apple.quicktime.udta` | QuickTime User Data |
| `com.apple.quicktime.mdta` | QuickTime Metadata  |
| `com.apple.itunes`         | iTunes metadata     |
| `org.mp4ra`                | MPEG-4 metadata     |
| `org.id3`                  | ID3 metadata        |

> TODO: How to map the MPEG-DASH event stream identifiers (`id` and `value`) to this `type` field?

`value`: An object with the metadata item key, data, and optionally a locale:

```
value = {
    key: String
    data: String | Number | Array | ArrayBuffer | Object
    locale: String
}
```

> TODO: Add example code to demonstrate API usage.

[This](https://trac.webkit.org/browser/webkit/trunk/LayoutTests/http/tests/media/track-in-band-hls-metadata.html) simple WebKit layout test loads various types of ID3 metadata from an HLS stream.

For more information, see [this session](https://developer.apple.com/videos/play/wwdc2014/504/) from WWDC 2014.

### Subscribing to receive in-band timed metadata cues

A web application can subscribe to receive specific timed metadata cues by setting a text track's `inBandMetadataTrackDispatchType`. For example, to receive [SCTE 35](https://www.scte.org/SCTEDocs/Standards/ANSI_SCTE%20214-3%202015.pdf) cues:

```javascript
const schemeIdUri = 'urn:scte:scte35:2013:bin';
const value = pid;
const video = document.getElementById('video');
const track = video.addTextTrack('metadata', {
  inBandMetadataTrackDispatchType: `${schemeIdUri} ${value}`
});

// video.currentTime has reached the cue start time
// through normal playback progression.
const cueEnterHandler = (event) => {
  const cue = event.target;

  // Parse the SCTE-35 message payload.
  // parseSCTE35Data() is similar to Comcast's scte35.js library,
  // adapted to take an ArrayBuffer as input.
  // https://github.com/Comcast/scte35-js/blob/master/lib/scte35.ts
  const scte35Message = parseSCTE35Data(cue.value.data);

  console.log(cue.startTime, cue.endTime, scte35Message.tableId, scte35Message.spliceCommandType);
};

// video.currentTime has reached the cue end time
// through normal playback progression.
const cueExitHandler = (event) => {
  const cue = event.target;
  console.log(cue.startTime, cue.endTime);
};

// A cue has been parsed from the media container.
track.oncuereceived((event) => {
  const cue = event.cue;
  console.log(cue.startTime, cue.endTime);

  // Attach enter/exit event handlers
  cue.onenter = cueEnterhandler;
  cue.onexit = cueExitHandler;
});
```

### Out-of-band timed metadata

> TODO: Add example code showing how a web application can construct `DataCue` objects with start and end times, event type, and data payload. For `emsg` events, the event type is defined by the `id` and (optional) `value` fields.

### Unknown end time support for streamed cues

A user wants to display content which is synchronized to a web media object and remains visible from the cue start time until the media finishes playing. For example, a common use case for [WebVMT](https://w3c.github.io/sdw/proposals/geotagging/webvmt/) is to add a map annotation cue which persists for the media duration. In the case of live streaming, the end of the media timeline is unknown and there is currently no value of `TextTrackCue.endTime` that can represent this.

It is proposed that a `TextTrackCue.endTime` value of `Infinity` be used to represent the end of media time. This is consistent with the approach used by the `HTMLMediaElement` [`duration`](https://html.spec.whatwg.org/multipage/media.html#offsets-into-the-media-resource) attribute, where `Infinity` represents the duration of an unbounded stream.

`TextTrackCue.endTime` is declared as a [`double`](https://heycam.github.io/webidl/#idl-double), which excludes non-finite values, so we propose to change this to [`unrestricted double`](https://heycam.github.io/webidl/#idl-unrestricted-double).

```javascript
const track = videoElement.addtrack('metadata');
// Create a cue from 5 secs to end of media
const cue = new DataCue(5.0, Infinity);
cue.value = { "moveto": { "lat": 51.504362, "lng": -0.076153 } };
cue.type = 'org.webvmt';
track.addCue(cue);
```

### Event triggering

> TODO: Add example code showing how a web application can be notified of in-band events as they are parsed from the media container or media stream.

> TODO: Add example code showing how a web application can respond to events (either in-band or out-of-band) as media playback reaches their position on the media timeline.

## Considered alternatives

### WebVTT metadata cues

Web applications today can use WebVTT metadata cues (the [VTTCue](https://www.w3.org/TR/webvtt1/#vttcue) API) to schedule out-of-band timed metadata events by serializing the timed metadata to a string format (JSON, for example) when creating the cue, and deserializing the data when the cue's `onenter` event is fired. Although this works in practice, the serialization/deserialization step should be unnecessary. It also does not directly support in-band timed metadata.

### Application level stream parsing

The current approach for handling in-band event information, implemented by libraries such as [dash.js](https://github.com/Dash-Industry-Forum/dash.js/wiki) and [hls.js](https://github.com/video-dev/hls.js), is to parse the media segments in JavaScript to extract the events and construct `VTTCue` objects.

On resource constrained devices such as smart TVs and streaming sticks, this leads to a significant performance penalty, which can have an impact on UI rendering updates if this is done on the UI thread (although we note the [proposal](https://github.com/wicg/media-source/blob/mse-in-workers-using-handle/mse-in-workers-using-handle-explainer.md) to make Media Source Extensions available to Worker contexts). There can also be an impact on the battery life of mobile devices. Given that the media segments will be parsed anyway by the user agent, parsing in JavaScript is an expensive overhead that could be avoided.

Avoiding parsing in JavaScript is also important for low latency video streaming applications, where minimizing the time taken to pass media content through to the media element's playback buffer is essential.

## Event synchronization

The Media Timed Events Task Force of the Media and Entertainment Interest Group has also [identified requirements for synchronization accuracy of event triggering](https://w3c.github.io/me-media-timed-events/#synchronization), which suggest changes to the [time marches on](https://html.spec.whatwg.org/multipage/media.html#time-marches-on) steps in HTML. These will be followed up separately to this `DataCue` proposal.

## References

This explainer is based on content from a [Note](https://w3c.github.io/me-media-timed-events/) written by the W3C Media and Entertainment Interest Group, and from a number of associated discussions, including the [TPAC breakout session on video metadata cues](https://github.com/w3c/strategy/issues/113#issuecomment-432971265).

## Acknowledgements

Thanks to Eric Carlson, François Daoust, Charles Lo, Nigel Megitt, Jon Piesing, Rob Smith, and Mark Vickers for their contribution and input to this document.
