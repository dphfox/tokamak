--!strict
--Licensed from @dphfox/tokamak under MIT

export type GraphObject = {
	type: "GraphObject",
	name: string,
	valid: boolean,
	validator: () -> (),
	using: {GraphObject},
	users: {GraphObject},

	use: (
		self: GraphObject,
		upstream: GraphObject
	) -> (),
	invalidate: (
		self: GraphObject
	) -> (),
	validate: (
		self: GraphObject
	) -> (),
	destroy: (
		self: GraphObject
	) -> ()
}

export type StateObject<T> = {
	type: "StateObject",
	name: string,
	graph: GraphObject,

	peek: (
		self: StateObject<T>
	) -> T,
	destroy: (
		self: StateObject<T>
	) -> ()
}

export type Value<R, W = R> = StateObject<R | W> & {
	value: W,

	set: (
		self: Value<R, W>,
		newValue: W
	) -> ()
}

return nil