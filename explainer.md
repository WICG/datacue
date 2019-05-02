# DataCue Explainer

## Introduction

HTTP Live Streaming (HLS) and MPEG Dynamic Adaptive Streaming over HTTP (MPEG-DASH) are the two main adaptive streaming formats in use on the web today. The media industry is coverging on the use of [MPEG Common Media Application Format (CMAF)](https://www.iso.org/standard/71975.html) as the common media delivery format.

There is a need in the media industry for an API to support metadata events synchronized to audio or video media, which are used to support use cases such as ad insertion or presentation of supplemental content alongside the audio or video. These events may be carried either "in-band", meaning that they are delivered within the audio or video media container or multiplexed with the media stream, or "out-of-band", meaning that they are delivered externally to the media container or media stream.

The [DataCue API](https://www.w3.org/TR/html53/semantics-embedded-content.html#text-tracks-exposing-inband-metadata) has been previously discussed as a means to deliver in-band event data to Web applications, but this is not implemented in all browser engines and is therefore not reflected in the [WHATWG HTML Living Standard](https://html.spec.whatwg.org/multipage/media.html#timed-text-tracks). There is previous discussion [here](https://groups.google.com/a/chromium.org/forum/#!topic/blink-dev/U06zrT2N-Xk), and an earlier liaison statement from HbbTV [here](https://lists.w3.org/Archives/Public/public-html/2013Dec/0015.html). We believe there is a recognized need for extending HTML to assist web applications in being able to properly process and render media-timed events.

## Use cases

Media timed events carry metadata that is related to points in time, or regions of time on the media timeline, which can be used to trigger retrieval and/or rendering of web resources synchronized with media playback. Such resources can be used to enhance user experience in the context of media that is being rendered. Some examples include display of social media feeds corresponding to a live video stream such as a sporting event, banner advertisements for sponsored content, accessibility-related assets such as large print rendering of captions, and display of track titles or images alongside an audio stream.

The following sections describe a few use cases in more detail.

### Dynamic content insertion

A media content provider wants to allow insertion of content, such as personalised video, local news, or advertisements, into a video media stream that contains the main program content. To achieve this, media timed events used to describe the points on the media timeline, known as splice points, where switching playback to inserted content is possible.

The Society for Cable and Televison Engineers (SCTE) specification [Digital Program Insertion Cueing for Cable (SCTE-35)](https://www.scte.org/SCTEDocs/Standards/SCTE%2035%202019.pdf) defines a data cue format for describing such insertion points. Use of these cues in MPEG-DASH and HLS streams is described in SCTE-35, sections 12.1 and 12.2.

### Lecture recording with slideshow

An HTML page contains title and info about the course/lecture, and two frames: a video of the lecturer in one, and their slides in the other. Each cue contains the URL of the slide to be presented, and the cue is active for the time range over which the slide should be visible.

### Audio stream with titles and images

A media content provider wants to provide visual information alongside an audio stream, such as an image of the artist and title of the current playing track, to give users live information about the content they are listening to.

Examples include [HLS timed metadata](https://developer.apple.com/library/archive/documentation/AudioVideo/Conceptual/HTTP_Live_Streaming_Metadata_Spec/Introduction/Introduction.html), which uses in-band ID3 metadata to carry the image content, and RadioVIS in [DVB-DASH, section 9.1.7](https://www.etsi.org/deliver/etsi_ts/103200_103299/103285/01.02.01_60/ts_103285v010201p.pdf), which defines in-band event messages that contain image URLs and text messages to be displayed, with information about when the content should be displayed in relation to the media timeline.

### Control messages for media streaming clients

A media streaming server uses media timed events to send control messages to media client library, such as [dash.js](https://github.com/Dash-Industry-Forum/dash.js/wiki). Typically, segmented streaming protocols such as HLS and MPEG-DASH make use of a manifest document that informs the client of the available encodings of a media stream, e.g., the Media Presentation Description (MPD) document in MPEG-DASH.

Should any of the content in the manifest document need to change, the client should refresh it by requesting an updated copy from the server. Section 5.10.4 of the [MPEG-DASH specification](https://standards.iso.org/ittf/PubliclyAvailableStandards/c065274_ISO_IEC_23009-1_2014.zip) describes an event type that is used to notify a client application. An in-band `emsg` event is used as an alternative to setting a cache duration in the response to the HTTP request for the manifest, so the client can refresh the MPD when it actually changes, as opposed to waiting for a cache duration expiry period to elapse. This also has the benefit of reducing the load on HTTP servers caused by frequent server requests.

### Synchronized map animations

A user records footage with metadata, including geolocation, on a mobile video device, e.g., drone or dashcam, to share on the web alongside a map, e.g., OpenStreetMap.

WebVMT is an open format for metadata cues, synchronized with a timed media file, that can be used to drive an online map rendered in a separate HTML element alongside the media element on the web page. The media playhead position controls presentation and animation of the map, e.g., pan and zoom, and allows annotations to be added and removed, e.g., markers, at specified times during media playback. Control can also be overridden by the user with the usual interactive features of the map at any time, e.g., zoom. Concrete examples are provided by the [tech demos at the WebVMT website](http://webvmt.org/demos).

### Media analysis visualization

A video image analysis system processes a media stream to detect and recognize objects shown in the video. This system generates metadata describing the objects, including timestamps that describe the when the objects are visible, together with position information (e.g., bounding boxes). A web application then uses this timed metadata to overlay labels and annotations on the video using HTML and CSS.

### Presentation of auxiliary content in live media

During a live media presentation, dynamic and unpredictable events may occur which cause temporary suspension of the media presentation. During that suspension interval, auxiliary content such as the presentation of UI controls and media files, may be unavailable. Depending on the specific user engagement (or not) with the UI controls and the time at which any such engagement occurs, specific web resources may be rendered at defined times in a synchronized manner. For example, a multimedia A/V clip along with subtitles corresponding to an advertisement, and which were previously downloaded and cached by the UA, are played out.

## In-band event processing

The exact set of in-band media timed events that we would aim to support is to be decided. MPEG DASH MPD and `emsg` events are a requirement, due to their inclusion in MPEG CMAF. We expect to discuss which other events to standardise as part of the incubation work.

We anticipate specifying the handling of in-band events in a separate set of specifications, following a registry approach with one specification per media format that describes the event details for that format, similar to the [Media Source Extensions Byte Stream Format Registry](https://www.w3.org/TR/mse-byte-stream-format-registry/). Another approach could be to update [Sourcing In-band Media Resource Tracks from Media Containers into HTML](https://dev.w3.org/html5/html-sourcing-inband-tracks/), either in its current form as a single document, or splitting it by media format and adding a registry.

## Proposed API and example code

The API follows recommendations made by the [Media Timed Events Task Force](https://w3c.github.io/me-media-timed-events/), and from a number of associated discussions, including the [TPAC breakout session on video metadata cues](https://github.com/w3c/strategy/issues/113#issuecomment-432971265).

The API is based on WebKit's `DataCue`, which extends the [HTML5 `DataCue` API](https://www.w3.org/TR/2018/WD-html53-20181018/semantics-embedded-content.html#text-tracks-exposing-inband-metadata) with two attributes to support non-text metadata, `type` and `value` (see IDL [here](https://trac.webkit.org/browser/webkit/trunk/Source/WebCore/html/track/DataCue.idl)):

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

### Subscribing to event streams

> TODO: Add example code showing how a web application can subscribe to receive specific event streams by event type, for example, `emsg` events of a given `id` and (optional) `value`.

### Out-of-band events

> TODO: Add example code showing how a web application can construct `DataCue` objects with start and end times, event type, and data payload. For `emsg` events, the event type is defined by the `id` and (optional) `value` fields.

### Unknown end time support for streamed cues

A common WebVMT use case is a [`DataCue`](https://www.w3.org/TR/html51/semantics-embedded-content.html#datacue-datacue) which remains active until the end of the linked media - for example, when a persistent map annotation is added. In the live (unbounded) streaming use case, the duration of the linked media is unknown when the cue is added so the [`endTime`](https://www.w3.org/TR/html51/semantics-embedded-content.html#dom-texttrackcue-endtime) attribute cannot be set numerically, as discussed in [w3c/sdw issue #1106](https://github.com/w3c/sdw/issues/1106).

As HTML already supports [`media.duration = Infinity`](https://www.w3.org/TR/html52/semantics-embedded-content.html#offsets-into-the-media-resource) to represent the `duration` of unbounded media streams, the existing definition could be extended to also include cue `endTime` and address this issue as follows:

```
const textTrack = videoElement.addTextTrack('metadata');
// create cue from 5 secs to end of media
const cue = new DataCue(5.0, Infinity);
cue.type = "org.mytype";
cue.value = { mykey: 'myvalue' };
textTrack.addCue(cue);
```

### Event triggering

> TODO: Add example code showing how a web application can be notified of in-band events as they are parsed from the media container or media stream.

> TODO: Add example code showing how a web application can respond to events (either in-band or out-of-band) as media playback reaches their position on the media timeline.

## Considered alternatives

### WebVTT metadata cues

Web applications today can use WebVTT metadata cues (the [VTTCue](https://www.w3.org/TR/webvtt1/#vttcue) API) to schedule out-of-band metadata events by serializing the event data to a string format (JSON, for example) when creating the cue, and deserializing the data when the cue is triggered. Although this works in practice, the serialization/deserialization step should be unnecessary. It also does not support in-band events.

### Application level stream parsing

The current approach for handling in-band event information, implemented by libraries such as [dash.js](https://github.com/Dash-Industry-Forum/dash.js/wiki) and [hls.js](https://github.com/video-dev/hls.js), is to parse the media segments in JavaScript to extract the events and construct `VTTCue` objects. On resource constrained devices such as smart TVs and streaming sticks, this leads to a significant performance penalty, which can have an impact on UI rendering updates if this is done on the UI thread. There can also be an impact on the battery life of mobile devices. Given that the media segments will be parsed anyway by the user agent, parsing in JavaScript is an expensive overhead that could be avoided.

## Event synchronization

The Media Timed Events Task Force has also [identified requirements for synchronization accuracy of event triggering](https://w3c.github.io/me-media-timed-events/#synchronization), which suggest changes to the [time marches on](https://html.spec.whatwg.org/multipage/media.html#time-marches-on) steps in HTML. These will be followed up separately to this `DataCue` proposal.

## References

This explainer is based on content from a [Note](https://w3c.github.io/me-media-timed-events/) written by the W3C Media and Entertainment Interest Group.

## Acknowledgements

Thanks to Eric Carlson, François Daoust, Charles Lo, Nigel Megitt, Jon Piesing, Rob Smith, and Mark Vickers for their contribution and input to this document.
