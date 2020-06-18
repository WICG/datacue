# DataCue Explainer

## Introduction

HTTP Live Streaming (HLS) and MPEG Dynamic Adaptive Streaming over HTTP (MPEG-DASH) are the two main adaptive streaming formats in use on the web today. The media industry is coverging on the use of [MPEG Common Media Application Format (CMAF)](https://www.iso.org/standard/71975.html) as the common media delivery format. HLS, MPEG-DASH, and MPEG CMAF all support delivery of timed metadata, i.e., metadata information that is synchronized to the audio or video media. Timed metadata can be used to support use cases such as dynamic content replacement, ad insertion, or presentation of supplemental content alongside the audio or video, or more generally, making changes to a web page, or executing application code triggered from JavaScript events, at specific points on the media timeline of an audio or video media stream.

The data may be carried either "in-band", meaning that they are delivered within the audio or video media container or multiplexed with the media stream, or "out-of-band", meaning that they are delivered externally to the media container or media stream. This explainer proposes bringing support for such timed metadata to the web platform.

## Use cases

### Lecture recording with slideshow

An HTML page contains title and information about the course or lecture, and two frames: a video of the lecturer in one and their slides in the other. Each timed metadata cue contains the URL of the slide to be presented, and the cue is active for the time range over which the slide should be visible.

### Dynamic content insertion

A media content provider wants to allow insertion of content, such as personalised video, local news, or advertisements, into a video media stream that contains the main program content. To achieve this, timed metadata is used to describe the points on the media timeline, known as splice points, where switching playback to inserted content is possible.

[SCTE 35](https://scte-cms-resource-storage.s3.amazonaws.com/ANSI_SCTE-35-2019a-1582645390859.pdf) defines a data cue format for describing such insertion points. Use of these cues in MPEG-DASH streams is described in [SCTE 214-1](https://scte-cms-resource-storage.s3.amazonaws.com/Standards/ANSI_SCTE%20214-1%202016.pdf), [SCTE 214-2](https://scte-cms-resource-storage.s3.amazonaws.com/Standards/ANSI_SCTE%20214-2%202016.pdf), and [SCTE 214-3](https://scte-cms-resource-storage.s3.amazonaws.com/Standards/ANSI_SCTE%20214-3%202015.pdf). Use in HLS streams is described in SCTE-35 section 12.2.

### Media player control messages

MPEG-DASH defines several control messages for media streaming clients (e.g., libraries such as [dash.js](https://github.com/Dash-Industry-Forum/dash.js/wiki)). Control messages exist for several scenarios, such as:

* The media player should refresh or update its copy of the manifest document (MPD)
* The media player should make an HTTP request to a given URL for analytics purposes
* The media presentation will end at a time earlier than expected

These messages may be carried as in-band `emsg` events in the media container files.

### Media stream with video and synchronized graphics

A content provider wants to provide synchronized graphical elements that may be rendered next to or on top of a video.

For example, in a talk show this could be a banner, shown in the lower third of the video, that displays the name of the guest. In a sports event, the graphics could show the latest lap times or current score, or highlight the location of the current active player. It could even be a full-screen overlay, to blend from one part of the program to another.

The graphical elements are described in a stream or file containing cues that describe the start and end time of each graphical element, similar to a subtitle stream or file. The web application takes this data as input and renders it on top of the video image according to the cues.

The purpose of rendering the graphical elements on the client device, rather than rendering them directly into the video image, is to allow the graphics to be optimized for the device's display parameters, such as aspect ratio and orientation. Another use case is adapting to user preferences, for localization or to improve accessibility.

This use case requires frame accurate synchronization of the content being rendered over the video.

### Synchronized map animations

A user records footage with metadata, including geolocation, on a mobile video device, e.g., drone or dashcam, to share on the web alongside a map, e.g., OpenStreetMap.

WebVMT is an open format for metadata cues, synchronized with audio or video media, that can be used to drive an online map rendered in a separate HTML element alongside the media element on the web page. The media playhead position controls presentation and animation of the map, e.g., pan and zoom, and allows annotations to be added and removed, e.g., markers, at specified times during media playback. Control can also be overridden by the user with the usual interactive features of the map at any time, e.g., zoom. Concrete examples are provided by the [tech demos at the WebVMT website](http://webvmt.org/demos).

### Media metadata search results

A user searches for online media matching certain metadata conditions, for example within a given distance of a geographic location or an acceleration profile corresponding to a traffic accident. Results are returned from a remote server using a RESTful API as a list in JSON format.

It should be possible for search results to be represented as media in the user agent, with linked metadata presented as `DataCue` objects programmatically to provide a common interface within the client web browser. Further details are given in the video metadata search experiments, proposed in the [OGC](http://www.opengeospatial.org) Ideas GitHub, to return [frames](https://github.com/opengeospatial/ideas/issues/91) and [clips](https://github.com/opengeospatial/ideas/issues/92).

> NOTE: Whether this use case requires any changes to the user agent or not is unclear without further investigation. If no changes are required, this capability should be demonstrated and the use case listed as a non-goal.

## HTTP adaptive streaming

HTTP adaptive streaming (HLS and MPEG-DASH) involves dividing the audio and video stream into small segments, each typically of a few seconds duration. Different encodings of the same content, known as representations, can be made available at varying quality levels (video resolution, bit rate), to allow a client application to select the most appropriate encoding for the playback device, as well as vary the bitrate in order to maintain continuous playback in response to changing network bandwidth conditions. These representations, and details of how to request the media segments are described in a manifest document.

Some user agents (notably Safari and HbbTV) include native support for adaptive streaming playback, rather than through a web application. In these cases, we need the user agent to expose to web applications any timed metadata cues that are carried either in-band with the media, or out-of-band via the manifest document.

Other user agents (Chrome, Edge, and Firefox) support adaptive streaming playback via [Media Source Extensions](https://www.w3.org/TR/media-source/). Here, a web application reads the manifest document, then requests the media segments and uses Media Source Extensions to pass the media to the user agent for playback. With these user agents, out-of-band timed metadata cues (i.e., those carried in the manifest document) must be created by the web application. In-band timed metadata cues may be created either by the web application, by parsing the media content before passing it to MSE using `appendBuffer()`, or by the user agent when it receives and decodes the media content from the web application.

## In-band timed metadata processing

The exact set of in-band timed metadata formats that we would aim to support is to be decided. MPEG DASH `emsg` events are a requirement, due to their inclusion in MPEG CMAF. We expect to discuss which other events to standardise, particularly HLS timed metadata, as part of the incubation work.

Where message types are widely supported (e.g., the MPEG-DASH specific events described above), the DataCue API would present the data in parsed form, so that it's convenient for web applications to access. Other message types, such as application-specific messages, would not be parsed directly by the user agent and instead would be presented to the web application in raw binary form.

In addition to specifying the `DataCue` API, we also need to specify the handling of in-band timed metadata. This could be done either in the DataCue spec, or in a separate set of specifications, following a registry approach with one specification per media format that describes the timed metadata details for that format, similar to the [Media Source Extensions Byte Stream Format Registry](https://www.w3.org/TR/mse-byte-stream-format-registry/). Another approach could be to update [Sourcing In-band Media Resource Tracks from Media Containers into HTML](https://dev.w3.org/html5/html-sourcing-inband-tracks/), either in its current form as a single document, or splitting it by media format and adding a registry.

## Proposed API and example code

The proposed API is based on the existing text track support in HTML and WebKit's `DataCue`. This extends the [HTML5 `DataCue` API](https://www.w3.org/TR/2018/WD-html53-20181018/semantics-embedded-content.html#text-tracks-exposing-inband-metadata) with two attributes to support non-text metadata, `type` and `value` that replace the existing `data` attribute. We also add a constructor that allows these fields to be initialized by web applications.

```webidl
interface DataCue : TextTrackCue {
    constructor(double startTime, unrestricted double endTime, any value, optional DOMString type);

    // Propose to deprecate / remove this attribute.
    attribute ArrayBuffer? data;

    // Proposed extensions.
    attribute any value;
    readonly attribute DOMString type;
};
```

`value`: Contains the message data, in either parsed or unparsed form. Unparsed data is exposed as an `ArrayBuffer`, and it is up to the web application to parse the data. For parsed data, the content and structure of the `value` field is expected to be in a more convenient form for web applications to use than an `ArrayBuffer`, such as a string, or an object. The `value` may be `null` if the message type contains no message data.

> TODO: WebIDL seems not to allow `any` to be [nullable](https://heycam.github.io/webidl/#idl-nullable-type).

`type`: A string that identifies the structure and content of the cue's `value`.

### Mapping to HLS timed metadata

WebKit supports the several kinds of timed metadata, using the following `type` values:

| Type                       | Purpose             |
| -------------------------- | ------------------- |
| `com.apple.quicktime.udta` | QuickTime User Data |
| `com.apple.quicktime.mdta` | QuickTime Metadata  |
| `com.apple.itunes`         | iTunes metadata     |
| `org.mp4ra`                | MPEG-4 metadata     |
| `org.id3`                  | ID3 metadata        |

In each case, the `value` attribute contains the parsed message data.

Additional information about existing support in WebKit can be found in [the IDL](https://trac.webkit.org/browser/webkit/trunk/Source/WebCore/html/track/DataCue.idl) and in [this layout test](https://trac.webkit.org/browser/webkit/trunk/LayoutTests/http/tests/media/track-in-band-hls-metadata.html), which loads various types of ID3 metadata from an HLS stream.

### Mapping to MPEG-DASH in-band emsg events

The `emsg` data structure is defined in section 5.10.3.3 of the [MPEG-DASH spec](https://www.iso.org/standard/79329.html).
Use of `emsg` within CMAF media is defined in section 7.4.5 of the [MPEG CMAF spec](https://www.iso.org/standard/79106.html) ([public draft](https://mpeg.chiariglione.org/sites/default/files/files/standards/parts/docs/w16186.zip)).

There are two versions in use, version 0 and 1:

```
aligned(8) class DASHEventMessageBox extends FullBox ('emsg', version, flags = 0) {
  if (version == 0) {
    string scheme_id_uri;
    string value;
    unsigned int(32) timescale_v0;
    unsigned int(32) presentation_time_delta;
    unsigned int(32) event_duration;
    unsigned int(32) id;
  } else if (version == 1) {
    unsigned int(32) timescale_v1;
    unsigned int(64) presentation_time;
    unsigned int(32) event_duration;
    unsigned int(32) id;
    string scheme_id_uri;
    string value;
  }
  unsigned int(8) message_data[];
}
```

| DataCue attribute     | emsg value                                                                                                   |
|-----------------------|--------------------------------------------------------------------------------------------------------------|
| `DOMString id`        | `id`                                                                                                         |
| `double startTime`    | Computed from `timescale` and `presentation_time_delta` or `presentation_time` (see Note)                    |
| `double endTime`      | Computed from `timescale`, `presentation_time_delta` or `presentation_time`, and `event_duration` (see Note) |
| `boolean pauseOnExit` | `false`                                                                                                      |
| `any value`           | Object containing parsed data from the `message_data` field                                                  |
| `DOMString type`      | `scheme_id_uri` + U+0020 + `value`                                                                           |

**Note:** The `timescale` value provides the timescale for the `presentation_time_delta` and `event_duration` fields, in ticks per second. Refer to [CMAF](https://mpeg.chiariglione.org/sites/default/files/files/standards/parts/docs/w16186.zip) for details on the interpretation of these fields.

### Mapping to MPEG-DASH MPD events

Timed event information may also be carried in the manifest document.

> TODO: Add example to show how a web app would construct a DataCue from an MPD event

## Examples

### Subscribing to receive in-band timed metadata cues

This example shows how to add a `cuechange` handler that can be used to receive media-timed data and event cues.

```javascript
const video = document.getElementById('video');

video.textTracks.addEventListener('addtrack', (event) => {
  const textTrack = event.track;

  if (textTrack.kind === 'metadata') {
    textTrack.mode = 'hidden';

    // See cueChangeHandler examples below
    textTrack.addEventLIstener('cuechange', cueChangeHandler);
  }
});
```

### MPEG-DASH callback event handler

```javascript
const cueChangeHandler = (event) => {
  const metadataTrack = event.target;
  const activeCues = metadataTrack.activeCues;

  for (let i = 0; i < activeCues.length; i++) {
    const cue = activeCues[i];

    if (cue.type === 'urn:mpeg:dash:event:callback:2015 1') {
      // The UA delivers parsed message data for this message type
      const url = cue.value;
      fetch(url).then(() => { console.log('Callback completed'); });
    }
  }
};
```

### SCTE-35 dynamic content insertion cue handler

This example shows how a web application can handle [SCTE 35](https://scte-cms-resource-storage.s3.amazonaws.com/Standards/ANSI_SCTE%20214-3%202015.pdf) cues, both in the case where the cues are parsed by the browser implementation, and where parsed by the web application.

```javascript
const cueChangeHandler = (event) => {
  const metadataTrack = event.target;
  const activeCues = metadataTrack.activeCues;

  for (let i = 0; i < activeCues.length; i++) {
    const cue = activeCues[i];

    // TODO: the emsg value contains the pid, add to cue.type here:
    if (cue.type === 'urn:scte:scte35:2013:bin') {
      // Parse the SCTE-35 message payload.
      // parseSCTE35Data() is similar to Comcast's scte35.js library,
      // adapted to take an ArrayBuffer as input.
      // https://github.com/Comcast/scte35-js/blob/master/lib/scte35.ts
      const scte35Message = (cue.value instanceof ArrayBuffer) ? parseSCTE35Data(cue.value) : cue.value;

      console.log(cue.startTime, cue.endTime, scte35Message.tableId, scte35Message.spliceCommandType);
    }
  }
};
```

### Cue enter/exit handlers

This example shows how a web application can use the proposed new `addcue` event to attach `enter` and `exit` handlers to each cue on the metadata track.

```javascript
// video.currentTime has reached the cue start time
// through normal playback progression
const cueEnterHandler = (event) => {
  const cue = event.target;
  console.log('cueEnter', cue.startTime, cue.endTime);
};

// video.currentTime has reached the cue end time
// through normal playback progression
const cueExitHandler = (event) => {
  const cue = event.target;
  console.log('cueExit', cue.startTime, cue.endTime);
};

// A cue has been parsed from the media container
const addCueHandler = (event) => {
  const cue = event.cue;

  // Attach enter/exit event handlers
  cue.onenter = cueEnterhandler;
  cue.onexit = cueExitHandler;
};

const video = document.getElementById('video');

video.textTracks.addEventListener('addtrack', (event) => {
  const textTrack = event.track;

  if (textTrack.kind === 'metadata') {
    textTrack.mode = 'hidden';

    // See cueChangeHandler examples below
    textTrack.addEventLIstener('addcue', addCueHandler);
  }
});
```

### Out-of-band timed metadata

> TODO: Add example code showing how a web application can construct `DataCue` objects with start and end times, event type, and data payload. For `emsg` events, the event type is defined by the `id` and (optional) `value` fields.

### Unknown end time support for streamed cues

A user wants to display content which is synchronized to a web media object and remains visible from the cue start time until the media finishes playing. For example, a common use case for [WebVMT](https://w3c.github.io/sdw/proposals/geotagging/webvmt/) is to add a map annotation cue which persists for the media duration. In the case of live streaming, the end of the media timeline is unknown and there is currently no value of `TextTrackCue.endTime` that can represent this.

It is proposed that a `TextTrackCue.endTime` value of `Infinity` be used to represent the end of media time. This is consistent with the approach used by the `HTMLMediaElement` [`duration`](https://html.spec.whatwg.org/multipage/media.html#offsets-into-the-media-resource) attribute, where `Infinity` represents the duration of an unbounded stream.

`TextTrackCue.endTime` is declared as a [`double`](https://heycam.github.io/webidl/#idl-double), which excludes non-finite values, so we propose to change this to [`unrestricted double`](https://heycam.github.io/webidl/#idl-unrestricted-double).

```javascript
const video = document.getElementById('video');
const track = video.addtrack('metadata');
// Create a cue from 5 secs to end of media
const data = { "moveto": { "lat": 51.504362, "lng": -0.076153 } };
const cue = new DataCue(5.0, Infinity, data, 'org.webvmt');
track.addCue(cue);
```

### Event triggering

> TODO: Add example code showing how a web application can be notified of in-band events as they are parsed from the media container or media stream.

> TODO: Add example code showing how a web application can respond to events (either in-band or out-of-band) as media playback reaches their position on the media timeline.

## Considered alternatives

### WebVTT metadata cues

Web applications today can use WebVTT metadata cues (the [VTTCue](https://www.w3.org/TR/webvtt1/#vttcue) API) to schedule out-of-band timed metadata events by serializing the timed metadata to a string format (JSON, for example) when creating the cue, and deserializing the data when the cue's `onenter` event is fired. Although this works in practice, the serialization/deserialization step should be unnecessary. It also does not support in-band timed metadata.

### Application level stream parsing

The current approach for handling in-band event information, implemented by libraries such as [dash.js](https://github.com/Dash-Industry-Forum/dash.js/wiki) and [hls.js](https://github.com/video-dev/hls.js), is to parse the media segments in JavaScript to extract the events and construct `VTTCue` objects.

On resource constrained devices such as smart TVs and streaming sticks, this leads to a significant performance penalty, which can have an impact on UI rendering updates if this is done on the UI thread (although we note the [proposal](https://github.com/wicg/media-source/blob/mse-in-workers-using-handle/mse-in-workers-using-handle-explainer.md) to make Media Source Extensions available to Worker contexts). There can also be an impact on the battery life of mobile devices. Given that the media segments will be parsed anyway by the user agent, parsing in JavaScript is an expensive overhead that could be avoided.

Avoiding parsing in JavaScript is also important for low latency video streaming applications, where minimizing the time taken to pass media content through to the media element's playback buffer is essential.

## Event synchronization

The Media Timed Events Task Force of the Media and Entertainment Interest Group has also [identified requirements for synchronization accuracy of event triggering](https://w3c.github.io/me-media-timed-events/#synchronization), which suggest changes to the [time marches on](https://html.spec.whatwg.org/multipage/media.html#time-marches-on) steps in HTML. These will be followed up separately to this `DataCue` proposal.

## References

This explainer is based on content from a [Note](https://w3c.github.io/me-media-timed-events/) written by the W3C Media and Entertainment Interest Group, and from a number of associated discussions, including the [TPAC breakout session on video metadata cues](https://github.com/w3c/strategy/issues/113#issuecomment-432971265). It is also closely related to the DASH-IF [DASH Player's Application Events and Timed Metadata Processing Models and APIs](https://dashif-documents.azurewebsites.net/Events/master/event.html) document.

## Acknowledgements

Thanks to Eric Carlson, François Daoust, Charles Lo, Nigel Megitt, Jon Piesing, Rob Smith, and Mark Vickers for their contribution and input to this document.
