## Explainer

This page explains the motivation for the [proposal to expose TextTrackCue constructor in the web interface](https://github.com/WICG/datacue/issues/35).

### TextTrackCue History

[VTTCue](https://www.w3.org/TR/webvtt1/#the-vttcue-interface) provides timed text support for video files on the web. This API is extended from [TextTrackCue](https://html.spec.whatwg.org/multipage/media.html#texttrackcue) which is widely supported in modern browsers.

![TextTrackCue_Support2502](https://github.com/user-attachments/assets/566d1a6c-50c9-4a1a-af55-6c3c9e0ce08e)
[Screenshot from caniuse.com/textrackcue](https://caniuse.com/texttrackcue)

[DataCue](https://wicg.github.io/datacue/#datacue-interface) was proposed to provide equivalent support for timed metadata and is also extended from TextTrackCue. DataCue was implemented and matured in Apple's WebKit, though that feature was subsequently dropped in accordance with W3C rules because only a single browser implemented this API.

### DataCue Design

[DataCue](https://wicg.github.io/datacue/#datacue-interface) implements a simple interface with `type` and `value` attributes which represent the cue type and cue content respectively. Any form of timed metadata can be stored in `value` and this is identified using `type` so that relevant cue content can be accessed quickly and easily.

### TextTrackCue Proposal

[TextTrackCue is an abstract base class](https://developer.mozilla.org/en-US/docs/Web/API/TextTrackCue) for all types of cue, which means that it is designed to be extended. Hence it does not directly specify any attributes related to cue content and expects these attributes to be defined by the programmer in the extended cue class. VTTCue and DataCue are both examples of extended cue classes which inherit the properties of TextTrackCue.

However, a user-defined cue extension is not currently possible in Javascript. The extended cue's constructor is unable to call the TextTrackCue constructor because this is prohibited by the web interface.

#### Extended Cue Example
````
// define extended cue class
class MyExtendedCue extends TextTrackCue {
    myCueContent; // cue content

    // extend constructor
    constructor(startTime, endTime, cueContent) {
        super(startTime, endTime); // inherit properties from TextTrackCue
        console.log('Cue start at ' + this.startTime + ', end at ' + this.endTime);

        this.myCueContent = cueContent; // set cue content
    }
}

// create an extended cue
const cue = new MyExtendedCue(0, 1, {hello: 'extended-cue'});
````
Permitting this `super` call in the web interface would enable custom cue extensions to be written in Javascript and make this widely-implemented feature accessible to the web community.

### Comparison With DataCue

Custom cue extensions are functionally equivalent to the DataCue API design:
 * The extended cue class name is equivalent to `DataCue.type`.
 * The cue content defined by the extended cue class is equivalent to `DataCue.value`.

In addition, an extended cue can define class functions which are not explicitly included in the DataCue API design.

The change required to enable this functionality is very simple and the potential benefit to the web community is significant. As a result, browser implementers are more likely to adopt the proposed change.

### Summary

This proposal yields equivalent functionality to DataCue API and addresses the challenge that caused the previous DataCue feature to be dropped.

## Demos

Example code has been created to test and demonstrate how custom cue extensions can be supported in web browsers if [this proposal](https://github.com/WICG/datacue/issues/35) is accepted.

### Custom Cues Demo

In this demo:

 1. Two user-defined custom cues are extended from TextTrackCue:
    * Countdown cue contains a number;
    * Colour cue contains an object with `foreground` and `background` attributes.
 1. A mixture of `CountdownCue` and `ColourCue` cues are created.
 1. Event listeners are added to `enter` and `exit` events for each cue.
 1. A TextTrack of `kind='metadata'` is attached to the `<video>` element in the page.
 1. All these cues are added to this track.

#### Custom Cue Example: Colour
````
class ColourCue extends TextTrackCue {
    // custom cue content
    background;
    foreground;

    constructor(startTime, endTime, content) {
        super(startTime, endTime); // inherit properties from TextTrackCue

        // set custom cue content
        if (typeof content == 'object') {
            this.background = content.background;
            this.foreground = content.foreground;
        }
    }    
}
````

When the video is played, the received cues drive event handlers which update count and colour display elements below the video. The handler code is able to accurately discriminate between the two types of custom cue and successfully update each element with the correct cue content for that display. An event log window records all cue events received by the handler, including the event type, media time, cue type and cue content - as shown below.

![CustomCue7_Firefox](https://github.com/user-attachments/assets/aebf91f6-ecb1-4dee-a494-d2e234bc0303)

This demo is built on a polyfill implementation of the proposed TextTrackCue API which demonstrates proof of concept and correct operation. The polyfill enables this demo to operate successfully in all web browsers tested - including Chrome, Safari and Firefox.

## Use Cases

### Cues Without Payloads & Cue Differentiation

#### Introduction

[TextTrackCue](https://html.spec.whatwg.org/multipage/media.html#texttrackcue) is an abstract base class with `startTime`, `endTime` and `id` attributes which enable [TextTrack](https://html.spec.whatwg.org/multipage/media.html#texttrack) to synchronise the cue's `enter` and `exit` events with a media timeline. This base class is agnostic of the cue content, though does not mandate any cue payload. The parking control use case is a practical example that demonstrates why no payload may be required and the exhibition venue use case highlights why base class extension is important to differentiate between different cue types.

#### Parking Control Use Case

A parking area is monitored by video cameras that record when vehicles arrive and depart. Vehicles are automatically identified by their registration number so that arrival and departure events can be properly associated. Registration numbers are converted to a hash code which obfuscates personal information, though is sufficiently unique to allow association of events with the correct vehicle.
````
class ParkingControlCue extends TextTrackCue {
    // no attributes

    constructor(startTime, endTime, hashCode) {        
        // inherit properties from TextTrackCue
        super(startTime, endTime, hashCode);
        console.log('Cue id ' + this.hashCode);
    }
}

const vehicleId = obfuscateReg('abc123xyz');
const cue = new ParkingControlCue(3600, 7200, vehicleId);
````
Each vehicle's visit is stored as a cue in an out-of-band metadata file format such as WebVMT that is separate from the video file. Personal information is anonymised so access to this timed metadata file need not be restricted to safeguard privacy rights, and these details can be processed for several purposes:

 * Parking regulations can be enforced by combining this metadata file with time and payment information to verify that each vehicle has complied with the rules.
 * Vehicles in breach of parking regulations can be spotted. In this case, access to the associated video file can be requested to identify the offending vehicle so that suitable action can be taken.
 * Electronic signs can display the number of free parking spaces in real time using streamed data.
 * Automatic barriers can block vehicle entrances if parking capacity is reached.
 * Parking utilisation can be measured and analysed.
 * Parking attendants can be deployed at busy times to quickly direct vehicles to empty spaces.

#### Cue Differentiation

The parking control example is part of a wider class of use cases that don't require a cue payload, including:
 * Passengers on a bus.
 * Vehicles at a refuelling station.
 * Visitors to an exhibition.

Cue types should always be differentiated by using their extended class names, but the exhibition venue use case serves to emphasise the importance of this requirement.

#### Exhibition Venue Use Case

An exhibition venue monitors its events using a network of CCTV cameras. The venue includes a parking area and needs to monitor both parking and exhibition visitors.
````
class ParkingCue extends TextTrackCue {
    constructor(startTime, endTime, id) {        
        super(startTime, endTime, id);
    }
}

class ExhibitionCue extends TextTrackCue {
    constructor(startTime, endTime, id) {        
        super(startTime, endTime, id);
    }
}

const vehicleId = obfuscateReg('abc123xyz');
const cue1 = new ParkingCue(7200, 10800, vehicleId);

const admissionId = ticketNumber('booking123456');
const cue2 = new ExhibitionCue(7800, 9400, admissionId);
````
Neither cue type has a payload, so the two cue types are structurally identical to each other and to the TextTrackCue base class. However, their cue types can be accurately differentiated from each other by using their extended class names.

Note that these cues may be generated by code from two different developers that are agnostic of each other. Using two different cue types also avoids ambiguity that would occur if any pair of `vehicleId` and `admissionId` values happen to be identical.