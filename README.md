# README for Penn Libraries iiif-ldn-demo

Manifest reworking. Make the manifests Penn manifests to simplify retrieval:

```json
{
  "@context": "http://iiif.io/api/presentation/2/context.json",
  "@id": "http://scta.info/iiif/melanderdeanima/penn855/manifest",
  "@type": "sc:Manifest",
  "label": "melanderdeanima/penn855",
  "description": "Manifest Description",
  "license": "https://creativecommons.org/publicdomain/zero/1.0/",
  "... etc. ..."
}
```

becomes:

```json
{
  "@context": "http://iiif.io/api/presentation/2/context.json",
  "@id": "http://library.upenn.edu/iiif/mscodex855/manifest",
  "@type": "sc:Manifest",
  "label": "mscodex855",
  "description": "Manifest Description",
  "license": "https://creativecommons.org/publicdomain/zero/1.0/",
  "... etc. ..."
}
```

Changing:

- `@id` to `http://library.upenn.edu/iiif/mscodex855/manifest`
- `label` to `mscodex855`

Likewise:

```json
{
  "@context": "http://iiif.io/api/presentation/2/context.json",
  "@id": "http://scta.info/iiif/rothwellcommentary/penn/manifest",
  "@type": "sc:Manifest",
  "label": "rothwellcommentary/penn",
  "description": "Manifest Description",
  "license": "https://creativecommons.org/publicdomain/zero/1.0/",
  "... etc. ..."
}
  ```

becomes

```json
{
  "@context": "http://iiif.io/api/presentation/2/context.json",
  "@id": "http://scta.info/iiif/mscodex686/manifest",
  "@type": "sc:Manifest",
  "label": "mscodex686",
  "description": "Manifest Description",
  "license": "https://creativecommons.org/publicdomain/zero/1.0/",
  "... etc. ..."
}
  ```