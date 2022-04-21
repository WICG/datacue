# DataCue

DataCue is a proposed web API to allow support for timed metadata, i.e., metadata information that is synchronized to audio or video media.

Timed metadata can be used to support use cases such as dynamic content replacement, ad insertion, or presentation of supplemental content alongside the audio or video, or more generally, making changes to a web page, or executing application code triggered from JavaScript events, at specific points on the media timeline of an audio or video media stream.

## Use cases

Timed metadata can be used to support use cases such as dynamic content replacement, ad insertion, or presentation of supplemental content alongside the audio or video, or more generally, making changes to a web page, or executing application code triggered from JavaScript events, at specific points on the media timeline of an audio or video media stream. The following sections describe some specific use cases in more detail.

### Lecture recording with slideshow

An HTML page contains title and information about the course or lecture, and two frames: a video of the lecturer in one and their slides in the other. Each timed metadata cue contains the URL of the slide to be presented, and the cue is active for the time range over which the slide should be visible.

### Media stream with video and synchronized graphics

A website wants to provide synchronized graphical elements that may be rendered next to or on top of a video.

For example, in a talk show this could be a banner, shown in the lower third of the video, that displays the name of the guest. In a sports event, the graphics could show the latest lap times or current score, or highlight the location of the current active player. It could even be a full-screen overlay, to blend from one part of the program to another.

The graphical elements are described in a stream or file containing cues that describe the start and end time of each graphical element, similar to a subtitle stream or file. The web application takes this data as input and renders it on top of the video image according to the cues.

The purpose of rendering the graphical elements on the client device, rather than rendering them directly into the video image, is to allow the graphics to be optimized for the device's display parameters, such as aspect ratio and orientation. Another use case is adapting to user preferences, for localization or to improve accessibility.

This use case requires frame accurate synchronization of the content being rendered over the video.

### Synchronized map animations

A user records footage with metadata, including geolocation, on a mobile video device such as a drone or dashcam, to share on the web alongside a map, e.g., OpenStreetMap.

WebVMT is an open format for metadata cues, synchronized with audio or video media, that can be used to drive an online map rendered in a separate HTML element alongside the media element on the web page. The media playhead position controls presentation and animation of the map, e.g., pan and zoom, and allows annotations to be added and removed, e.g., markers, at specified times during media playback. Control can also be overridden by the user with the usual interactive features of the map at any time, e.g., zoom. Concrete examples are provided by the [tech demos at the WebVMT website](http://webvmt.org/demos).

### Media metadata search results

A user searches for online media matching certain metadata conditions, for example within a given distance of a geographic location or an acceleration profile corresponding to a traffic accident. Results are returned from a remote server using a RESTful API as a list in JSON format.

It should be possible for search results to be represented as media in the user agent, with linked metadata presented as `DataCue` objects programmatically to provide a common interface within the client web browser. Further details are given in the video metadata search experiments, proposed in the [OGC](http://www.opengeospatial.org) Ideas GitHub, to return [frames](https://github.com/opengeospatial/ideas/issues/91) and [clips](https://github.com/opengeospatial/ideas/issues/92).

> NOTE: Whether this use case requires any changes to the user agent or not is unclear without further investigation. If no changes are required, this capability should be demonstrated and the use case listed as a non-goal.

## Event delivery

HTTP Live Streaming (HLS) and MPEG Dynamic Adaptive Streaming over HTTP (MPEG-DASH) are the two main adaptive streaming formats in use on the web today. The media industry is coverging on the use of [MPEG Common Media Application Format (CMAF)](https://www.iso.org/standard/71975.html) as the common media delivery format. HLS, MPEG-DASH, and MPEG CMAF all support delivery of timed metadata, i.e., metadata information that is synchronized to the audio or video media.

Both HLS and MPEG-DASH use a combination of encoded media files and manifest files that identify the available streams their respective URLs.

Some user agents (notably Safari and HbbTV) include native support for adaptive streaming playback, rather than through use of [Media Source Extensions](https://www.w3.org/TR/media-source/). In these cases, we need the user agent to expose to web applications any timed metadata cues that are carried either in-band with the media (i.e., delivered within the audio or video media container or multiplexed with the media stream), or out-of-band via the manifest document.

## Proposed API

The proposed API is based on the existing [text track support](https://html.spec.whatwg.org/multipage/media.html#timed-text-tracks) in HTML and WebKit's `DataCue`. This extends the [HTML5 `DataCue` API](https://www.w3.org/TR/2018/WD-html53-20181018/semantics-embedded-content.html#text-tracks-exposing-inband-metadata) with two attributes to support non-text metadata, `type` and `value` that replace the existing `data` attribute. We also add a constructor that allows these fields to be initialized by web applications.

```webidl
interface DataCue : TextTrackCue {
  constructor(double startTime, unrestricted double endTime, any value, optional DOMString type);

  // Propose to deprecate / remove this attribute.
  attribute ArrayBuffer data;

  // Proposed extensions.
  attribute any value;
  readonly attribute DOMString type;
};
```

`value`: Contains the message data, which may be in any arbitrary data structure.

`type`: A string that can be used to identify the structure and content of the cue's `value`.

## User agent-generated DataCue instances

Some user agents may automatically generate `DataCue` timed metadata cues while playing media. For example, WebKit supports several kinds of timed metadata in HLS streams, using the following `type` values:

| Type                       | Purpose             |
| -------------------------- | ------------------- |
| `com.apple.quicktime.udta` | QuickTime User Data |
| `com.apple.quicktime.mdta` | QuickTime Metadata  |
| `com.apple.itunes`         | iTunes metadata     |
| `org.mp4ra`                | MPEG-4 metadata     |
| `org.id3`                  | ID3 metadata        |

Additional information about existing support in WebKit can be found in [the IDL](https://trac.webkit.org/browser/webkit/trunk/Source/WebCore/html/track/DataCue.idl) and in [this layout test](https://trac.webkit.org/browser/webkit/trunk/LayoutTests/http/tests/media/track-in-band-hls-metadata.html), which loads various types of ID3 metadata from an HLS stream.

This proposal does not seek to standardize UA-generated `DataCue` schemas, but the proposed API is intended to support this usage.

Other proposals may be developed for this purpose, e.g., for the above or MPEG-DASH timed metadata events.

## Code examples

### Create an unbounded DataCue with geolocation data

```javascript
const video = document.getElementById('video');
const textTrack = video.addtrack('metadata');
// Create a cue from 5 secs to end of media
const data = { "moveto": { "lat": 51.504362, "lng": -0.076153 } };
const cue = new DataCue(5.0, Infinity, data, 'org.webvmt');
textTrack.addCue(cue);
```

### Create a DataCue from an in-band DASH 'emsg' box

```javascript
// Parse the media segment to extract timed metadata cues
// contained in DASH 'emsg' boxes
function extractEmsgBoxes(mediaSegment) {
  // etc.
}

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

function createDataCues(events, textTrack) {
  events.forEach(event => {
    const cue = new DataCue(
      event.startTime,
      event.endTime,
      event.payload,
      event.schemeIdUri
    );

    // Attach enter/exit event handlers
    cue.onenter = cueEnterhandler;
    cue.onexit = cueExitHandler;

    textTrack.addCue(cue);
  });
}

// Append the segment to the MSE SourceBuffer
function appendSegment(segment) {
  // etc.
  sourceBuffer.appendBuffer(segment);
}

const video = document.getElementById('video');
const textTrack = video.addtrack('metadata');

// Fetch a media segment, parse and create DataCue instances,
// and append the segment for playback using Media Source Extensions.
fetch('/media-segments/12345.m4s')
  .then(response => response.arrayBuffer())
  .then(buffer => {
    const events = extractEmsgBoxes(buffer);
    createDataCues(events, textTrack)

    appendSegment(buffer);
  });
```

### Create a DataCue from a DASH MPD event

> TODO: Add example code showing how a web application can construct `DataCue` objects with start and end times, event type, and data payload from a DASH MPD event, where the MPD is parsed by the web application

## Considered alternatives

### WebVTT metadata cues

Web applications today can use WebVTT metadata cues (the [`VTTCue`](https://www.w3.org/TR/webvtt1/#vttcue) API) to schedule timed metadata events by serializing the data to a string format (JSON, for example) when creating the cue, and deserializing the data when the cue's `onenter` event is fired. Although this works in practice, `DataCue` avoids the need for the serialization/deserialization steps.

`DataCue` is also sementically consistent with timed metadata use cases, where `VTTCue` is designed for subtitles and captions. `VTTCue` contains a lot of API surface related to caption layout and presentation, which are not relevant to timed metadata cues.

## Event synchronization

The Media Timed Events Task Force of the Media and Entertainment Interest Group has also [identified requirements for synchronization accuracy of event triggering](https://w3c.github.io/me-media-timed-events/#synchronization), which suggest changes to the [time marches on](https://html.spec.whatwg.org/multipage/media.html#time-marches-on) steps in HTML. These will be followed up separately to this `DataCue` proposal.

## References

This explainer is based on content from a [Note](https://w3c.github.io/me-media-timed-events/) written by the W3C Media and Entertainment Interest Group, and from a number of associated discussions, including the [TPAC breakout session on video metadata cues](https://github.com/w3c/strategy/issues/113#issuecomment-432971265). It is also closely related to the DASH-IF [DASH Player's Application Events and Timed Metadata Processing Models and APIs](https://dashif-documents.azurewebsites.net/Events/master/event.html) document.

## Acknowledgements

Thanks to Eric Carlson, François Daoust, Charles Lo, Nigel Megitt, Jon Piesing, Rob Smith, and Mark Vickers for their contribution and input to this document.
