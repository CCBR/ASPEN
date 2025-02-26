document.addEventListener("DOMContentLoaded", function() {
    document.querySelectorAll("pre").forEach(function(pre) {
        let button = document.createElement("button");
        button.className = "copy-button";
        button.innerText = "Copy";
        
        // Ensure button does not get copied
        button.addEventListener("click", function(event) {
            event.stopPropagation(); // Prevent event bubbling
            let codeBlock = pre.querySelector("code"); // Select only the code block
            if (codeBlock) {
                let textToCopy = codeBlock.innerText.trim(); // Trim removes trailing newlines
                navigator.clipboard.writeText(textToCopy).then(() => {
                    button.innerText = "Copied!";
                    setTimeout(() => { button.innerText = "Copy"; }, 1500);
                }).catch(err => console.error("Copy failed", err));
            }
        });

        pre.style.position = "relative"; // Ensure button stays positioned inside block
        pre.appendChild(button);
    });
});
