# WKEY Assignment Submission - 02/05/26

## Roblox Experience Link
https://www.roblox.com/games/72177521282117/wkey-assignment

## Github Repository Link
https://github.com/Diegw/wkey-assignment

---

## Instructions

Upon entering the experience, you will see a conveyor next to you. There are two ways to interact with it:

- You will see a GUI with red and green buttons to change variables that affect the conveyor.
- You can also get near three control points (start, middle, end), represented by small grey boxes. Each one has its own GUI that allows you to change its position and update the conveyor shape.

---

## Process

Once I got the task, I subdivided it into chunks:

- **First: Conveyor logic.**  
  Something that moves from one point to another. For visualization, I used multiple small assets to build the conveyor, since they allow curving the shape. Using a single asset would make rotation along the curve impossible.

- **Second: Luggage.**  
  At first, I thought I could just spawn the luggage on top of the conveyor and let it move. However, this was not reliable. Because of that, I decided to make the luggage follow the same path as the conveyor segments. Only at the end did I search for an asset in the Toolbox to use.

- **Third: Remaining functionalities.**  
  Animations for spawning and despawning, changing luggage color, assigning a unique ID per instantiated luggage, using a ProximityPrompt to print that ID, and exposing behavior modifications through UI buttons.

---

## Explanation

- The first thing I like to do is determine priorities. For example, deciding whether it’s better to have the movement functionality working before adding spawn animations. This helps me go from absolutely necessary features to “nice to have” ones.

- I knew I could just reference a single conveyor, but I thought it would be better to retrieve all conveyors from a folder and then set up their behavior in a scalable way.

- There is no built-in Bezier curve support in Roblox, so I searched for formulas to implement a quadratic Bézier curve, which requires three positions. I’m not an expert in math, but I was able to gather enough information from forums to implement it correctly.

- I quickly discarded the idea of letting the luggage simply ride the conveyor, since it didn’t work reliably at first. I tried adjusting physics properties like friction and mass, but that didn’t solve it. I also considered welding the luggage to conveyor segments, but that would have introduced extra complexity when detaching it at the end of the path. Since I already had the conveyor movement logic in place, I decided to reuse that behavior for the luggage.

- For animations, since I’m not an animator, I kept it simple by using tweening and some particle effects to achieve a decent result.

- Color changes were straightforward, just modifying the MeshPart properties when needed.

- I wasn’t completely sure what was meant by “part ID.” Since Roblox doesn’t provide a unique ID per instance by default, I implemented a simple function to assign one. I avoided using HttpService for this due to its rate limitations.

- When working on the UI, I initially used a BillboardGui but realized that button press events were not triggering correctly, so I switched to a SurfaceGui.

---

## Insights

- From the beginning, I had the idea of making the conveyor shape modifiable. This required using a quadratic Bézier curve to define its path.

- Later on, I realized that the shape could also be updated live by allowing the user to move the control points in real time.

- There are still areas that could be improved. For example, using object pooling instead of instantiating and destroying assets would reduce pressure on the garbage collector. Another issue I noticed toward the end is some jitter in the movement. This happens because the CFrame updates are handled on the server. Moving that part of the logic to the client would result in smoother movement.
