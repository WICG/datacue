# DataCue Explainer

## Introduction

There is a need in the media industry for an API to support metadata events synchronized to audio or video media, specifically for both out-of-band event streams and in-band discrete events (e.g., [MPD-carriage and emsg events in MPEG DASH](http://standards.iso.org/ittf/PubliclyAvailableStandards/c065274_ISO_IEC_23009-1_2014.zip)).

These media timed events can be used to support use cases such as ad insertion or presentation of supplemental content alongside the audio or video.

On resource constrained devices such as smart TVs and streaming sticks, parsing media segments to extract event information leads to a significant performance penalty, which can have an impact on UI rendering updates if this is done on the UI thread. There can also be an impact on the battery life of mobile devices. Given that the media segments will be parsed anyway by the user agent, parsing in JavaScript is an expensive overhead that could be avoided.

The [DataCue API](https://www.w3.org/TR/html53/semantics-embedded-content.html#text-tracks-exposing-inband-metadata) has been previously discussed as a means to deliver in-band event data to Web applications, but this is not implemented in all browser engines and is therefore not reflected in the [WHATWG HTML Living Standard](https://html.spec.whatwg.org/multipage/media.html#timed-text-tracks). There is previous discussion [here](https://groups.google.com/a/chromium.org/forum/#!topic/blink-dev/U06zrT2N-Xk), and an earlier liaison statement from HbbTV [here](https://lists.w3.org/Archives/Public/public-html/2013Dec/0015.html). Whether DataCue should be taken up again or another API should be developed, we believe there is a recognized need for extending the existing HTML specification to assist web applications in being able to properly process and render media-timed events.

The Media & Entertainment Interest Group has a draft use case and requirements document [here](https://w3c.github.io/me-media-timed-events/).

## Current Implementations

This section includes details of existing web browsers which support `DataCue` implementations for video metadata cues.

### WebKit implementation

WebKit supports `DataCue`. The original interface was extended with two attributes to support non-text metadata, `type` and `value`:

```
interface DataCue : TextTrackCue {
    attribute ArrayBuffer data; // Always empty

    // Proposed extensions.
    attribute any value;
    readonly attribute DOMString type;
};
```

https://trac.webkit.org/browser/webkit/trunk/Source/WebCore/html/track/DataCue.idl

`type`: A string identifying the type of metadata:

| Type                       | Purpose             |
| -------------------------- | ------------------- |
| `com.apple.quicktime.udta` | QuickTime User Data |
| `com.apple.quicktime.mdta` | QuickTime Metadata  |
| `com.apple.itunes`         | iTunes metadata     |
| `org.mp4ra`                | MPEG-4 metadata     |
| `org.id3`                  | ID3 metadata        |

`value`: An object with the metadata item key, data, and optionally a locale:

```
value = {
    key: String
    data: String | Number | Array | ArrayBuffer | Object
    locale: String
}
```

[This](https://trac.webkit.org/browser/webkit/trunk/LayoutTests/http/tests/media/track-in-band-hls-metadata.html) simple WebKit layout test loads various types of ID3 metadata from an HLS stream.

For more information, see [this session](https://developer.apple.com/videos/play/wwdc2014/504/) from WWDC 2014.

We expect to use this WebKit interface as the basis for a standardised API.

## Use Cases

Use cases related to video metadata cues are identified in this section, including those in the [Media Timed Events Task Force Note](https://w3c.github.io/me-media-timed-events/).

### Audio stream with titles and images

A media content provider wants to provide visual information alongside an audio stream, such as an image of the artist and title of the current playing track, to give users live information about the content they are listening to.

Examples include HLS timed metadata, which uses in-band ID3 metadata to carry the image content, and RadioVIS in DVB-DASH, section 9.1.7, which defines in-band event messages that contain image URLs and text messages to be displayed, with information about when the content should be displayed in relation to the media timeline.

### MPEG-DASH manifest expiry notifications

Section 5.10.4 of MPEG-DASH describes a specific event that is used to notify a DASH player web application that it should refresh its copy of the manifest (MPD) document. An in-band emsg event is used an alternative to setting a cache duration in the response to the HTTP request for the manifest, so the client can refresh the MPD when it actually changes, so reducing the load on HTTP servers caused by frequent server requests.

### Synchronized map animations

A user records footage with metadata, including geolocation, on a mobile video device, e.g., drone or dashcam, to share on the web alongside a map, e.g., OpenStreetMap.

WebVMT is an open format for metadata cues, synchronized with a timed media file, that can be used to drive an online map rendered in a separate HTML element alongside the media element on the web page. The media playhead position controls presentation and animation of the map, e.g., pan and zoom, and allows annotations to be added and removed, e.g., markers, at specified times during media playback. Control can also be overridden by the user with the usual interactive features of the map at any time, e.g., zoom. Concrete examples are provided by the [tech demos at the WebVMT website](http://webvmt.org/demos).

### Media analysis visualization

A video image analysis system processes a media stream to detect and recognize objects shown in the video. This system generates metadata describing the objects, including timestamps that describe the when the objects are visible, together with position information (e.g., bounding boxes). A web application then uses this timed metadata to overlay labels and annotations on the video using HTML and CSS.

### Presentation of auxiliary content in live media

During a live media presentation, dynamic and unpredictable events may occur which cause temporary suspension of the media presentation. During that suspension interval, auxiliary content such as the presentation of UI controls and media files, may be unavailable. Depending on the specific user engagement (or not) with the UI controls and the time at which any such engagement occurs, specific web resources may be rendered at defined times in a synchronized manner. For example, a multimedia A/V clip along with subtitles corresponding to an advertisement, and which were previously downloaded and cached by the UA, are played out.

## New Requirements

The following new requirements have been identified from gap analysis undertaken by and recommendations made by the [Media Timed Events Task Force](https://w3c.github.io/me-media-timed-events/), and from a number of associated discussions, including the [TPAC breakout session on video metadata cues](https://github.com/w3c/strategy/issues/113#issuecomment-432971265).

### In-band events support

The exact set of media in-band events that we would aim to support is to be decided. MPEG DASH MPD and `emsg` events are a requirement, and we expect to discuss which other events to standardise as part of the incubation work.

### Unknown end time support for streamed cues

Streamed media is currently supported by HTML, including `media.duration` of `Infinity` for unbounded streams. However, no details are given to set an unknown `TextTrackCue.endTime`, for example when the cue is displayed until the end of the media, and we expect to discuss clarification of how to set unknown times.

### Additional metadata type support

Several types of metadata are already identified in the `DataCue` specification, and others requirements may arise during the expected discussion.
