# teleprompt-revealjs extension for Quarto

This extension provides a `revealjs` theme designed for use with a teleprompter and/or smart board.

Description: This extension provides a custom `revealjs` theme for use with a smart board and teleprompter for lecture video recording. It provides text and images on a flat black background, allowing the superposition of the video feed of the person giving the lecture. The content of the slides takes up 80% of the left side, leaving room for the person on the video feed to appear on the right side.

Any text in a div labeled "notes" is exported as simple text that can be used in the teleprompter.

## Installing

Install the extension by running the following command:

```bash
quarto add paytonej/teleprompt-revealjs
```

This will install the extension under the `_extensions` subdirectory.
If you're using version control, you will want to check in this directory.

## Using

To use the teleprompt-revealjs theme in your Quarto presentation, specify it as a format in your document YAML header:

```yaml
format: teleprompt-revealjs
```

Place your script in fenced divs labeled "notes":
```{md}
::: {.notes}
In one of the most memorable scenes in the 1986 film "Ferris Bueller's Day Off", an economics teacher delivers a comically monotone lecture to a room of bored students. The economics teacher says:

"In 1930, the Republican-controlled House of Representatives, in an effort to alleviate the effects of the... Anyone? Anyone?... Great Depression, passed the... Anyone? Anyone?... tariff bill? The Hawley-Smoot Tariff Act? Which, anyone? Raised or lowered? Raised tariffs, in an effort to collect more revenue for the federal government. Did it work? Anyone? Anyone know the effects? It did not work, and the United States sank deeper into the Great Depression."

Amazingly, the scene was *improvised* by actor Ben Stein (who was the son of an economist).
:::
```

This will produce a txt file in your output folder that lists the slide the notes appear on:

```{markdown}
Slide 1
In one of the most memorable scenes in the 1986 film "Ferris Bueller's Day Off", an economics teacher delivers a comically monotone lecture to a room of bored students. The economics teacher says:

"In 1930, the Republican-controlled House of Representatives, in an effort to alleviate the effects of the... Anyone? Anyone?... Great Depression, passed the... Anyone? Anyone?... tariff bill? The Hawley-Smoot Tariff Act? Which, anyone? Raised or lowered? Raised tariffs, in an effort to collect more revenue for the federal government. Did it work? Anyone? Anyone know the effects? It did not work, and the United States sank deeper into the Great Depression."

Amazingly, the scene was *improvised* by actor Ben Stein (who was the son of an economist).
----------------------------------------
Slide 2
...
```

## Example

You can find usage examples here
- Documentation of the capabilities can be found here: [template-demo.qmd](template-demo.qmd)
- Here is the source code for a minimal example: [example.qmd](example.qmd).

## References

* <https://github.com/paytonej/ucinci-revealjs>

## License

This project is licensed under the terms of the [MIT License](LICENSE).

## Contributing

Contributions, issues, and feature requests are welcome! Feel free to open an issue or submit a pull request.
