const scores = require("./evilScores.json");

// console.log(Object.keys(scores).filter(id => scores[id] == 1).length);

for (let i = 0; i < 40; i++) {
    console.log(`INT ${i}`);
    let binary = Object.keys(scores).slice(i * 256, (i + 1) * 256).map(id => scores[id]).join("")
    console.log(binary);
}