# DataCue Explainer

There is a need in the media industry for an API to support metadata events synchronized to audio or video media, specifically for both out-of-band event streams and in-band discrete events (e.g., [MPD-carriage and emsg events in MPEG DASH](http://standards.iso.org/ittf/PubliclyAvailableStandards/c065274_ISO_IEC_23009-1_2014.zip)).

These media timed events can be used to support use cases such as ad insertion or presentation of supplemental content alongside the audio or video.

On resource constrained devices such as smart TVs and streaming sticks, parsing media segments to extract event information leads to a significant performance penalty, which can have an impact on UI rendering updates if this is done on the UI thread. There can also be an impact on the battery life of mobile devices. Given that the media segments will be parsed anyway by the user agent, parsing in JavaScript is an expensive overhead that could be avoided.

The [DataCue API](https://www.w3.org/TR/html53/semantics-embedded-content.html#text-tracks-exposing-inband-metadata) has been previously discussed as a means to deliver in-band event data to Web applications, but this is not implemented in all browser engines and is therefore not reflected in the [WHATWG HTML Living Standard](https://html.spec.whatwg.org/multipage/media.html#timed-text-tracks). There is previous discussion [here](https://groups.google.com/a/chromium.org/forum/#!topic/blink-dev/U06zrT2N-Xk), and an earlier liaison statement from HbbTV [here](https://lists.w3.org/Archives/Public/public-html/2013Dec/0015.html). Whether DataCue should be taken up again or another API should be developed, we believe there is a recognized need for extending the existing HTML specification to assist web applications in being able to properly process and render media-timed events.

The Media & Entertainment Interest Group has a draft use case and requirements document [here](https://w3c.github.io/me-media-timed-events/).

## WebKit implementation

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

## In-band events support

The exact set of media in-band events that we would aim to support is to be decided. MPEG DASH MPD and `emsg` events are a requirement, and we expect to discuss which other events to standardise as part of the incubation work.

