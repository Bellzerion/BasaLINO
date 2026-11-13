# Immersive Story Content Guide

This guide covers the visual and pronunciation assets used by the BasaLINO
reader. Keep story assets in their story-specific folders so Mayon and Ibalong
retain distinct visual identities.

## Add a vocabulary recording

1. Record a clear, short pronunciation with minimal background noise.
2. Save it as an MP3 under `assets/audio/<language>/`, for example
   `assets/audio/bikol/marhay.mp3`.
3. Add the asset path to that vocabulary hint in
   `assets/data/chapters.json`:

   ```json
   {
     "vocabularyId": "mayon-ch1-marhay",
     "word": "marhay",
     "definition": "Good or beautiful.",
     "audioAsset": "assets/audio/bikol/marhay.mp3"
   }
   ```

Recorded audio is attempted first. If it cannot be played, the reader uses the
device's installed speech voice. English uses an English voice; Tagalog tries
Filipino/Tagalog voices, then English. Bikol currently falls back to Filipino
and then English because device TTS engines may not include a Bikol voice.
Speech uses the device's TTS engine; offline availability depends on the voice
installed and selected by that engine.

The English, Tagalog, Bikol, and SFX folders under `assets/audio/` are
registered in `pubspec.yaml`. Register any new language folder there as well.
After adding or removing assets, run `flutter pub get` and restart the app.

## Add an illustration

Place original artwork in a story-specific folder, such as
`assets/images/mayon/` or `assets/images/ibalong/`. SVG and raster image assets
are supported. Reference the artwork from the scene's `imageAssetKey`:

```json
{
  "imageAssetKey": "assets/images/mayon/mountain_formation.svg"
}
```

Artwork can stand alone or provide the static background/fallback for animated
scene media. Keep important subjects centered and readable when cropped to a
wide card.

## Add a GIF scene

1. Add an optimized, original animated GIF under `assets/gifs/<story>/`.
2. Keep dimensions and frame count modest; scene cards may appear while the
   learner scrolls.
3. Reference it with `gifAsset` in the scene annotation:

   ```json
   {
     "paragraphIndex": 3,
     "gifAsset": "assets/gifs/mayon/eruption.gif",
     "assetKey": "assets/scenes/mayon_formation.json",
     "imageAssetKey": "assets/images/mayon/eruption.svg"
   }
   ```

GIFs are the primary animated media. When both GIF and Lottie are supplied,
the GIF is shown with the Lottie animation layered over it in the expanded
viewer. Without a GIF, Lottie is used; static artwork remains available as the
fallback and reduced-motion experience. GIF-only, Lottie-only, artwork-only,
and combined scenes are supported.

The Mayon and Ibalong GIF folders are registered in `pubspec.yaml`. Register
new story folders there as well. Keep GIFs in the matching story folder; do
not reuse Mayon artwork for Ibalong or vice versa.

## Add scene metadata

Add annotations to the chapter's `scenes` array in
`assets/data/chapters.json`. `paragraphIndex` is zero-based; the scene appears
after that paragraph. All media and learning metadata are optional, so older
scene entries continue to work.

```json
{
  "paragraphIndex": 3,
  "title": "The Volcano Erupts",
  "description": "A story moment learners can explore.",
  "label": "Mount Mayon erupts",
  "sceneType": "volcano",
  "importanceLevel": "high",
  "gifAsset": "assets/gifs/mayon/eruption.gif",
  "assetKey": "assets/scenes/volcano_eruption.json",
  "imageAssetKey": "assets/images/mayon/eruption.svg",
  "vocabularyContext": "sumabog means to erupt.",
  "educationalNote": "Mayon is an active volcano in Albay.",
  "soundEffectAsset": "assets/audio/sfx/volcano_rumble.mp3"
}
```

`soundEffectAsset` is optional and is never played automatically. When present,
the scene viewer shows a control that learners can use to play or stop it.
Keep sound effects short and non-essential to understanding the story.

After adding content, run the immersive reader tests and verify every referenced
file exists. Reduced-motion mode keeps illustrations visible and disables
animated scene motion.
