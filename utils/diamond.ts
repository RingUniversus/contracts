/**
 * This file contains some confusing terminology that needs to be clarified:
 *
 * 1. A `selector` is the first four bytes of the call data for a function call. For
 *    example, `foo()` hashes to the `0xc2985578` selector. The Diamond spec operates
 *    exclusively with selectors, which aren't human-readable and can't be reversed.
 *    Ring Universus use a service called [4byte](https://www.4byte.directory) to store
 *    selectors and do a reverse lookup when needed.
 *
 * 2. A `signature` is the function name & the types of its arguments (but not return
 *    type). For example, `supportsInterface(bytes4)` is the signature for a function
 *    in the ERC165 spec. These are human-readable and should be used them whenever
 *    presenting information to operators.
 *
 * Much care must be taken when dealing with these and converting between them because
 * TypeScript only knows them as `string`.
 */

import readline from "readline";

import type { JsonFragment } from "@ethersproject/abi";
import chalk from "chalk";
import Table from "cli-table";
import fetch from "node-fetch";

import DiamondCutFacetABI from "./DiamondCutFacet.json";
import DiamondLoupeFacetABI from "./DiamondLoupeFacet.json";
import OwnershipFacetABI from "./OwnershipFacet.json";
import {
  Contract,
  FormatType,
  Fragment,
  FragmentType,
  FunctionFragment,
  id,
  Interface,
  ZeroAddress,
} from "ethers";

export const enum FacetCutAction {
  Add = 0,
  Replace = 1,
  Remove = 2,
}

// Turns an abiElement into a signature string, like `"init(bytes4)"`
export function toSignature(abiElement: unknown): string {
  return Fragment.from(abiElement as JsonFragment).format();
}

/* In the form of `[ContractNameMatcher, IgnoredSignature]` */
const signaturesToIgnore = [
  // The SolidState contracts adds a `supportsInterface` function,
  // but we already provide that function through DiamondLoupeFacet
  ["RUOblivionFacet$", "supportsInterface(bytes4)"],
  // ["RUOblivionFacet$", "OwnershipTransferred(address,address)"],
  ["RUCoinFacet$", "supportsInterface(bytes4)"],
  // ["RUCoinFacet$", "OwnershipTransferred(address,address)"],
  ["RUEquipmentFacet$", "supportsInterface(bytes4)"],
  // ["RUEquipmentFacet$", "OwnershipTransferred(address,address)"],
  ["RUPlayerFacet$", "supportsInterface(bytes4)"],
  // ["RUPlayerFacet$", "OwnershipTransferred(address,address)"],
  ["RURingFacet$", "supportsInterface(bytes4)"],
  // ["RURingFacet$", "OwnershipTransferred(address,address)"],
  ["RUTownFacet$", "supportsInterface(bytes4)"],
  // ["RUTownFacet$", "OwnershipTransferred(address,address)"],
] as const;

export function isIncluded(contractName: string, signature: string): boolean {
  const isIgnored = signaturesToIgnore.some(
    ([contractNameMatcher, ignoredSignature]) => {
      if (contractName.match(contractNameMatcher)) {
        // console.log("signature: ", signature);
        return signature === ignoredSignature;
      } else {
        return false;
      }
    }
  );

  return !isIgnored;
}

interface FacetCut {
  facetAddress: string;
  action: FacetCutAction;
  functionSelectors: string[];
}

// A facet stored in the smart contract doesn't have an `action` property
interface Facet {
  facetAddress: string;
  functionSelectors: string[];
}

interface HasInterface {
  interface: Interface;
}

interface Changeset {
  added: [string, string][]; // Array of [ContractName, Signature]
  replaced: [string, string][]; // Array of [ContractName, Signature]
  ignored: [string, string][]; // Array of [ContractName, Signature]
  // These are selectors and need to be looked up in 4bytes
  removed: string[];
}

interface SelectorDiff {
  add: string[];
  replace: string[];
}

interface FourBytesJson {
  count: number;
  results: {
    id: number;
    text_signature: string;
  }[];
}

export class DiamondChanges {
  /**
   * While calling `changes.getFacetCuts` and `changes.getRemoveCuts`, we track
   * the changes in this `changes` object. We then can call `changes.verify` to
   * present the user with a table of changes and prompt them to confirm the changes.
   */
  private changes: Changeset;

  private previous?: Facet[];

  /**
   * Build a series of `cuts` while tracking changes.
   *
   * @param previous Previous facet `cuts`, used to create a diff of `cuts` for an upgrade
   */
  constructor(previous?: Facet[]) {
    this.previous = previous;

    this.changes = {
      added: [],
      replaced: [],
      ignored: [],
      // These are selectors and need to be looked up in 4bytes
      removed: [],
    };
  }

  /**
   * Gets the "add" & "replace" facet `cuts` given a contract name and contract object.
   * If previous facets are were provided to the constructor, it'll diff the selectors
   * to determine if they should be added or replaced.
   *
   * @param contractName The name of the contract
   * @param contract The ethers Contract object
   * @returns The `cuts` for your Diamond
   */
  public async getFacetCuts(
    contractName: string,
    contract: Contract
  ): Promise<FacetCut[]> {
    const facetCuts = [];

    if (this.previous) {
      const diff = this.diffSelectors(contractName, contract, this.previous);

      if (diff.add.length > 0) {
        facetCuts.push({
          facetAddress: await contract.getAddress(),
          action: FacetCutAction.Add,
          functionSelectors: diff.add,
        });
      }
      if (diff.replace.length > 0) {
        facetCuts.push({
          facetAddress: await contract.getAddress(),
          action: FacetCutAction.Replace,
          functionSelectors: diff.replace,
        });
      }
    } else {
      facetCuts.push({
        facetAddress: await contract.getAddress(),
        action: FacetCutAction.Add,
        functionSelectors: this.getSelectors(contractName, contract),
      });
    }

    // console.log("facetCuts: ", facetCuts);
    return facetCuts;
  }

  /**
   * Gets the "remove" `cuts` given a set of cuts to be made.
   * Requires previous facets are were provided to the constructor.
   * Will diff the provided `cuts` to determine which need to be removed.
   * Automatically filters any selectors from `DiamondCutFacet`, `DiamondLoupeFacet`,
   * and `OwnershipFacet`, which are all required by the Diamond spec.
   *
   * @param cuts A list of "add"/"remove" `cuts` to made
   * @returns The `cuts` for your Diamond
   */
  public getRemoveCuts(cuts: FacetCut[]): FacetCut[] {
    if (!this.previous) {
      throw new Error(
        "You must construct DiamondChanges with previous cuts to find removals"
      );
    }
    const functionSelectors = cuts.flatMap((cut) => cut.functionSelectors);

    const seenSelectors = new Set(functionSelectors);

    const toRemove = [] as string[];
    for (const { functionSelectors } of this.previous) {
      for (const selector of functionSelectors) {
        // TODO: Do we need to check `isIncluded`? I don't want to deal with contract names
        if (
          !seenSelectors.has(selector) &&
          !this.isDiamondSpecSelector(selector)
        ) {
          toRemove.push(selector);
          this.changes.removed.push(selector);
        }
      }
    }

    const removeCuts = [];

    if (toRemove.length) {
      removeCuts.push({
        facetAddress: ZeroAddress,
        action: FacetCutAction.Remove,
        functionSelectors: toRemove,
      });
    }

    return removeCuts;
  }

  /**
   * Presents the Diamond `cut` changeset to the user as a table of
   * "added"/"replaces"/"removed" and prompts them to approve the changest.
   *
   * If they approve the changeset, the returned promise is resolved with `true`, or
   * `false` if it isn't approved.
   *
   * @returns `true` if the changeset should be cut into the Diamond or `false` otherwise
   */
  public async verify(): Promise<boolean> {
    const table = new Table({
      head: ["Change", "Signature", "Facet"],
      style: {
        // Avoiding the red color heading
        head: undefined,
      },
    });

    // In order, we show 1. ignored, 2. replaced, 3. added, 4. removed
    // because added and removed selectors are probably the selectors to
    // be the most concerned about (and ignored the least)

    for (const [contractName, signature] of this.changes.ignored) {
      table.push([chalk.gray("Ignored"), signature, contractName]);
    }

    for (const [contractName, signature] of this.changes.replaced) {
      table.push([chalk.green("Replaced"), signature, contractName]);
    }

    for (const [contractName, signature] of this.changes.added) {
      table.push([chalk.blue("Added"), signature, contractName]);
    }

    for (const selector of this.changes.removed) {
      const signature = await this.lookupSelector(selector);
      table.push([chalk.red("Removed"), signature, ""]);
    }

    if (table.length > 0) {
      console.log(table.toString());
      const rl = readline.createInterface({
        input: process.stdin,
        output: process.stdout,
      });
      return new Promise((resolve) => {
        rl.question(
          "Review the table of Diamond changes. Proceed with upgrade? yN ",
          (answer) => {
            if (
              answer.toLowerCase() === "y" ||
              answer.toLowerCase() === "yes"
            ) {
              resolve(true);
            } else {
              resolve(false);
            }
          }
        );
      });
    } else {
      table.push(["None", "", ""]);
      console.log(table.toString());
      return false;
    }
  }

  private getFragmements(contract: HasInterface): ReadonlyArray<Fragment> {
    return contract.interface.fragments;
  }

  private getFunctionFragment(
    contract: HasInterface
  ): ReadonlyArray<FunctionFragment> {
    return contract.interface.fragments
      .filter((f) => f.type == "function")
      .map((f) => f as FunctionFragment);
  }

  // private getSignatures(contract: HasInterface): string[] {
  //   return Object.keys(
  //     contract.interface.fragments
  //       .filter((f) => f.type === "function")
  //       .map((f) => f.format("minimal"))
  //   );
  // }

  // private getSelector(contract: HasInterface, signature: string): string {
  //   return contract.interface.getSighash(signature);
  // }

  private getSelectors(contractName: string, contract: HasInterface): string[] {
    const fragements = this.getFunctionFragment(contract);
    // const signatures = this.getSignatures(contract);
    const selectors: string[] = [];

    for (const f of fragements) {
      if (isIncluded(contractName, f.format("sighash"))) {
        selectors.push(f.selector);
        this.changes.added.push([contractName, f.format("sighash")]);
      }
    }

    // console.log("this.changes: ", this.changes);
    // console.log("selectors: ", selectors);
    return selectors;
  }

  private diffSelectors(
    contractName: string,
    contract: HasInterface,
    previous: Facet[]
  ): SelectorDiff {
    const fragements = this.getFunctionFragment(contract);

    const diff: SelectorDiff = { add: [], replace: [] };

    for (const f of fragements) {
      if (isIncluded(contractName, f.format("sighash"))) {
        const selector = f.selector;
        const selectorExists = previous.some(({ functionSelectors }) => {
          return functionSelectors.some((val) => selector === val);
        });
        if (selectorExists) {
          this.changes.replaced.push([contractName, f.format("sighash")]);
          diff.replace.push(selector);
        } else {
          this.changes.added.push([contractName, f.format("sighash")]);
          diff.add.push(selector);
        }
      } else {
        this.changes.ignored.push([contractName, f.format("sighash")]);
      }
    }

    return diff;
  }

  private isDiamondSpecSelector(selector: string): boolean {
    const diamondCutFacetInterface = new Interface(DiamondCutFacetABI);
    const diamondLoupeFacetInterface = new Interface(DiamondLoupeFacetABI);
    const ownershipFacetInterface = new Interface(OwnershipFacetABI);

    const diamondCutSignatures = this.getFunctionFragment({
      interface: diamondCutFacetInterface,
    });
    const diamondLoupeSignatures = this.getFunctionFragment({
      interface: diamondLoupeFacetInterface,
    });
    const ownershipSignatures = this.getFunctionFragment({
      interface: ownershipFacetInterface,
    });
    return [
      ...diamondCutSignatures.map((signature) => signature.selector),
      ...diamondLoupeSignatures.map((signature) => signature.selector),
      ...ownershipSignatures.map((signature) => signature.selector),
    ].includes(selector);
  }

  /**
   * Takes a selector and attempts to look it up using the 4byte service. See the header
   * comment to understand why this is necessary.
   *
   * @param selector The selector to lookup
   * @returns The signature if it can be looked up or the selector and "(unable to find a signature)" if not
   */
  private async lookupSelector(selector: string): Promise<string> {
    const fallbackMsg = `${selector} (unable to find a signature)`;

    try {
      const response = await fetch(
        `https://www.4byte.directory/api/v1/signatures/?hex_signature=${selector}`,
        {
          headers: {
            "Content-Type": "application/json",
          },
        }
      );

      const json: FourBytesJson | undefined = await response.json();

      if (json && json.count > 0) {
        // Join with `|` because there theoretically could be some overlap
        return json.results
          .flatMap((result) => result.text_signature)
          .join(" | ");
      } else {
        return fallbackMsg;
      }
    } catch {
      return fallbackMsg;
    }
  }
}
